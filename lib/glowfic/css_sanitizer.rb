# frozen_string_literal: true

# Sanitizes user-authored "skin" CSS before it is injected into a page.
#
# Skins are allowed to restyle the whole page and can be shared publicly, so
# this is a security boundary, not a cosmetic nicety. The rules enforced here:
#
#   * Only allowlisted properties survive (unknown/dangerous ones are dropped).
#   * `!important` is stripped from every declaration, so the application can
#     always win a specificity battle with its own trailing safety overrides
#     (e.g. keeping content warnings visible).
#   * External resources are blocked: `@import`, `@font-face`, and any `url(...)`
#     that is not a `data:` URI are dropped. This neutralises CSS-based tracking
#     and the attribute-selector exfiltration attack, which both rely on an
#     outbound request.
#   * Clickjacking primitives are blocked: `position: fixed` / `position: sticky`
#     and legacy script vectors (`expression()`, `-moz-binding`, `behavior`).
#   * Only safe at-rules are kept (`@media`, `@supports`, `@keyframes`).
#
# Anything it cannot confidently parse or vet is discarded rather than passed
# through.
class Glowfic::CssSanitizer
  # Skins are capped so a single skin cannot bloat every page it touches.
  MAX_LENGTH = 100_000

  ALLOWED_AT_RULES = %w[media supports].freeze
  KEYFRAMES_AT_RULES = %w[keyframes -webkit-keyframes -moz-keyframes -o-keyframes].freeze

  VENDOR_PREFIX = /\A-(?:webkit|moz|ms|o)-/

  # Allowlist of CSS properties (vendor prefixes are stripped before lookup).
  # Deliberately broad enough for real theming but free of script/resource
  # loading and navigation-style escape hatches.
  ALLOWED_PROPERTIES = Set.new(%w[
    color opacity visibility display box-sizing
    background background-color background-image background-position
    background-size background-repeat background-attachment background-clip
    background-origin background-blend-mode mix-blend-mode

    width height min-width max-width min-height max-height aspect-ratio
    margin margin-top margin-right margin-bottom margin-left
    padding padding-top padding-right padding-bottom padding-left

    border border-width border-style border-color border-radius
    border-top border-right border-bottom border-left
    border-top-width border-right-width border-bottom-width border-left-width
    border-top-style border-right-style border-bottom-style border-left-style
    border-top-color border-right-color border-bottom-color border-left-color
    border-top-left-radius border-top-right-radius
    border-bottom-left-radius border-bottom-right-radius
    border-collapse border-spacing border-image
    outline outline-width outline-style outline-color outline-offset
    box-shadow

    font font-family font-size font-style font-weight font-variant
    font-stretch font-feature-settings line-height letter-spacing word-spacing
    text-align text-align-last text-decoration text-decoration-color
    text-decoration-line text-decoration-style text-transform text-indent
    text-shadow text-overflow text-justify white-space word-break word-wrap
    overflow-wrap hyphens vertical-align tab-size writing-mode direction
    unicode-bidi quotes content

    list-style list-style-type list-style-position list-style-image

    position top right bottom left z-index float clear

    flex flex-grow flex-shrink flex-basis flex-direction flex-wrap flex-flow
    justify-content justify-items justify-self align-content align-items
    align-self order gap row-gap column-gap place-content place-items place-self

    grid grid-template grid-template-columns grid-template-rows
    grid-template-areas grid-auto-columns grid-auto-rows grid-auto-flow
    grid-column grid-row grid-area grid-column-start grid-column-end
    grid-row-start grid-row-end grid-column-gap grid-row-gap grid-gap

    overflow overflow-x overflow-y resize
    transform transform-origin transform-style perspective perspective-origin
    backface-visibility
    transition transition-property transition-duration transition-timing-function
    transition-delay
    animation animation-name animation-duration animation-timing-function
    animation-delay animation-iteration-count animation-direction
    animation-fill-mode animation-play-state
    filter backdrop-filter

    table-layout caption-side empty-cells
    object-fit object-position
    cursor user-select pointer-events
    columns column-count column-width column-rule column-fill
    column-span
  ]).freeze

  def self.call(css)
    new(css).sanitized
  end

  def initialize(css)
    # Comments are dropped from the output anyway, and stripping them up front
    # also sidesteps a stack-overflow in the parser on pathological runs of
    # consecutive comments.
    text = css.to_s.gsub(/\/\*.*?\*\//m, ' ')
    @css = text.byteslice(0, MAX_LENGTH).to_s
  end

  def sanitized
    return '' if @css.strip.empty?

    render_nodes(Crass.parse(@css)).strip
  rescue StandardError, SystemStackError
    # Never let malformed or pathological input bubble up as a usable stylesheet.
    ''
  end

  private

  def render_nodes(nodes)
    Array(nodes).filter_map { |node| render_node(node) }.join("\n")
  end

  def render_node(node)
    case node[:node]
      when :style_rule then render_style_rule(node)
      when :at_rule    then render_at_rule(node)
    end
  end

  def render_style_rule(node)
    selector = node.dig(:selector, :value).to_s.strip
    return if selector.empty? || dangerous_value?(selector)

    declarations = sanitize_declarations(node[:children])
    return if declarations.empty?

    body = declarations.map { |decl| "  #{decl};" }.join("\n")
    "#{selector} {\n#{body}\n}"
  end

  def render_at_rule(node)
    name = node[:name].to_s.downcase
    prelude = Crass::Parser.stringify(node[:prelude]).strip
    return if node[:block].nil?
    return if dangerous_value?(prelude)

    # everything else (@import, @font-face, @charset, @namespace, @page, ...) is dropped
    return unless ALLOWED_AT_RULES.include?(name) || KEYFRAMES_AT_RULES.include?(name)

    inner = render_nodes(Crass.parse(Crass::Parser.stringify(node[:block])))
    return if inner.strip.empty?

    "@#{name} #{prelude} {\n#{inner}\n}"
  end

  def sanitize_declarations(children)
    css = Crass::Parser.stringify(children)
    Crass::Parser.parse_properties(css).filter_map do |decl|
      next unless decl[:node] == :property

      sanitize_declaration(decl)
    end
  end

  def sanitize_declaration(decl)
    name = decl[:name].to_s.strip.downcase
    value = decl[:value].to_s.strip
    return if name.empty? || value.empty?
    return unless property_allowed?(name)
    return if dangerous_value?(value)
    return if name == 'position' && value.match?(/\b(?:fixed|sticky)\b/i)

    # `!important` is intentionally not re-emitted.
    "#{name}: #{value}"
  end

  def property_allowed?(name)
    return true if name.start_with?('--') # custom properties (still value-checked)

    ALLOWED_PROPERTIES.include?(name.sub(VENDOR_PREFIX, ''))
  end

  def dangerous_value?(value)
    lower = value.downcase
    return true if lower.include?('expression(')
    return true if lower.include?('javascript:')
    return true if lower.include?('-moz-binding')
    return true if lower.include?('behavior:')
    # any url(...) that is not a data: URI implies an outbound request
    return true if lower.match?(/url\(\s*['"]?\s*(?!data:)[^)]/)

    false
  end
end
