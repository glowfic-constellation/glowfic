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

  # Whether the CSS asks for anything the safe tier strips for security reasons
  # (external resources, fixed/sticky positioning, !important, script vectors).
  # Used to route a skin to mod review before it can affect other readers.
  def self.dangerous?(css)
    sanitizer = new(css)
    sanitizer.sanitized
    sanitizer.dangerous?
  end

  # Prefix every style-rule selector with `scope` (a descendant prefix such as
  # ":root:root") so an injected skin out-ranks the application's own theming
  # rules — many of which use :nth-child or #id selectors that a bare ".x" skin
  # selector cannot beat — without relying on !important, which the sanitizer
  # strips for non-owners. Keyframe selectors (from/to/percent) are never scoped.
  # Falls back to returning the input unchanged if it cannot be parsed.
  def self.scope(css, scope)
    render_scoped(Crass.parse(css.to_s), scope)
  rescue StandardError, SystemStackError
    css.to_s
  end

  def self.render_scoped(nodes, scope)
    Array(nodes).filter_map { |node| scope_node(node, scope) }.join("\n")
  end
  private_class_method :render_scoped

  def self.scope_node(node, scope)
    case node[:node]
      when :style_rule then scope_style_rule(node, scope)
      when :at_rule    then scope_at_rule(node, scope)
    end
  end
  private_class_method :scope_node

  def self.scope_style_rule(node, scope)
    selector = node.dig(:selector, :value).to_s.strip
    return if selector.empty?

    scoped = split_selector_list(selector).map { |part| "#{scope} #{part}" }.join(', ')
    body = Crass::Parser.stringify(node[:children]).strip
    "#{scoped} {\n#{body}\n}"
  end
  private_class_method :scope_style_rule

  def self.scope_at_rule(node, scope)
    name = node[:name].to_s.downcase
    prelude = Crass::Parser.stringify(node[:prelude]).strip
    return "@#{name} #{prelude};" if node[:block].nil?

    inner =
      if KEYFRAMES_AT_RULES.include?(name)
        Crass::Parser.stringify(node[:block]).strip # keyframe selectors must stay literal
      else
        render_scoped(Crass.parse(Crass::Parser.stringify(node[:block])), scope)
      end
    "@#{name} #{prelude} {\n#{inner}\n}"
  end
  private_class_method :scope_at_rule

  # Split a selector list on top-level commas only (commas inside () or [] are
  # part of :not()/:is()/attribute selectors and must not split the list).
  def self.split_selector_list(selector)
    parts = []
    buffer = +''
    depth = 0
    selector.each_char do |char|
      case char
        when '(', '[' then depth += 1; buffer << char
        when ')', ']' then depth -= 1 if depth > 0; buffer << char
        when ','
          if depth.zero?
            parts << buffer
            buffer = +''
          else
            buffer << char
          end
        else buffer << char
      end
    end
    parts << buffer
    parts.map(&:strip).reject(&:empty?)
  end
  private_class_method :split_selector_list

  def initialize(css)
    # Comments are dropped from the output anyway, and stripping them up front
    # also sidesteps a stack-overflow in the parser on pathological runs of
    # consecutive comments.
    text = css.to_s.gsub(/\/\*.*?\*\//m, ' ')
    @css = text.byteslice(0, MAX_LENGTH).to_s
    @dangerous = false
  end

  def sanitized
    return '' if @css.strip.empty?

    render_nodes(Crass.parse(@css)).strip
  rescue StandardError, SystemStackError
    # Never let malformed or pathological input bubble up as a usable stylesheet.
    ''
  end

  # True if sanitizing dropped or defused a security-relevant construct. Only set
  # after #sanitized has run. Unsupported-but-harmless properties do not count.
  def dangerous?
    @dangerous
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

    # @import / @font-face pull in external resources; flag and drop them.
    # (@import has no block, so this must run before the block check below.)
    @dangerous = true if %w[import font-face].include?(name)

    return if node[:block].nil?
    return if dangerous_value?(prelude)

    # everything else (@charset, @namespace, @page, ...) is dropped
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
    return unless property_allowed?(name) # unsupported, but not dangerous
    if dangerous_value?(value)
      @dangerous = true
      return
    end
    # Angle brackets are never needed in a declaration value, and allowing them
    # (e.g. content: "</style><script>...") would let a skin break out of the
    # inline <style> element it is injected into.
    if value.match?(/[<>]/)
      @dangerous = true
      return
    end
    if name == 'position' && value.match?(/\b(?:fixed|sticky)\b/i)
      @dangerous = true
      return
    end

    # `!important` is intentionally not re-emitted (but is flagged as dangerous).
    @dangerous = true if decl[:important]
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
