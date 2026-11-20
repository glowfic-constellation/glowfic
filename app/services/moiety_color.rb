# frozen_string_literal: true

# Places a moiety hex code in CIE LCh(uv), the space HSLuv is built on. Its hue is
# the HSLuv hue, so sorting by it puts moieties in the same order they sit around the
# wheel on the moiety explorer page (which uses the hsluv JS library).
class MoietyColor
  # Below this chroma a color reads as gray, and its hue is noise.
  GRAY_CHROMA = 8.0

  REF_U = 0.19783000664283
  REF_V = 0.46831999493879
  KAPPA = 903.2962962
  EPSILON = 0.0088564516

  attr_reader :lightness, :chroma, :hue

  # Moieties saved before hex validation existed may not parse; those sort last.
  def self.sort_key_for(hex)
    new(hex).sort_key
  rescue ArgumentError
    [2, 0, 0]
  end

  def initialize(hex)
    hex = hex.to_s.delete_prefix('#')
    hex = hex.chars.map { |c| c * 2 }.join if hex.length == 3
    raise ArgumentError, "not a hex color: #{hex.inspect}" unless hex.match?(/\A\h{6}\z/)

    r, g, b = hex.scan(/../).map { |c| to_linear(c.to_i(16) / 255.0) }
    x = (0.41239079926595 * r) + (0.35758433938387 * g) + (0.18048078840183 * b)
    y = (0.21263900587151 * r) + (0.71516867876775 * g) + (0.072192315360733 * b)
    z = (0.019330818715591 * r) + (0.11919477979462 * g) + (0.95053215224966 * b)

    @lightness = y <= EPSILON ? y * KAPPA : (116 * Math.cbrt(y)) - 16
    if @lightness.zero?
      @chroma = 0.0
      @hue = 0.0
      return
    end

    divider = x + (15 * y) + (3 * z)
    u = 13 * @lightness * ((4 * x / divider) - REF_U)
    v = 13 * @lightness * ((9 * y / divider) - REF_V)
    @chroma = Math.hypot(u, v)
    @hue = (Math.atan2(v, u) * 180 / Math::PI) % 360
  end

  def gray?
    chroma < GRAY_CHROMA
  end

  # Colors around the wheel from red, each hue light to dark; then grays light to dark.
  def sort_key
    return [1, 0, -lightness] if gray?
    [0, hue.round, -lightness]
  end

  private

  def to_linear(channel)
    channel > 0.04045 ? ((channel + 0.055) / 1.055)**2.4 : channel / 12.92
  end
end
