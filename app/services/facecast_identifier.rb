# frozen_string_literal: true
# Guesses the facecast depicted by an image by querying SauceNAO's reverse
# image search API, returning a label suitable for a character's facecast (pb)
# field. SauceNAO is geared towards anime, art and other fictional sources, so
# it returns results in a "Character (Source)" shape that matches how facecasts
# for fictional characters are commonly written. Disabled unless a
# SAUCENAO_API_KEY is configured.
class FacecastIdentifier
  API_URL = 'https://saucenao.com/search.php'
  # SauceNAO reports match confidence as a percentage; ignore weak guesses.
  MIN_SIMILARITY = 55.0
  TIMEOUT = 10

  class Error < StandardError; end

  def self.enabled?
    api_key.present?
  end

  def self.api_key
    ENV.fetch('SAUCENAO_API_KEY', nil)
  end

  def initialize(image_url)
    @image_url = image_url
  end

  # Returns a best-guess facecast label, or nil when nothing confident is found.
  def identify
    raise Error, "Reverse image search is not configured." unless self.class.enabled?
    raise Error, "There is no image to search." if @image_url.blank?

    parse(request)
  end

  private

  def request
    response = HTTParty.get(API_URL, timeout: TIMEOUT, query: {
      api_key: self.class.api_key,
      output_type: 2, # JSON
      numres: 1,
      db: 999, # search all indexes
      url: @image_url,
    },)

    raise Error, "Reverse image search failed (status #{response.code})." unless response.success?
    response.parsed_response
  rescue HTTParty::Error, SocketError, Timeout::Error, Errno::ECONNREFUSED
    raise Error, "Reverse image search could not be reached."
  end

  def parse(body)
    results = body.is_a?(Hash) ? body['results'] : nil
    return nil if results.blank?

    top = results.first
    return nil if top['header'].to_h['similarity'].to_f < MIN_SIMILARITY

    label_from(top['data'])
  end

  def label_from(data)
    return nil unless data.is_a?(Hash)

    character = first_value(data['characters'])
    source = first_value(data['material']) || first_value(data['source']) || first_value(data['title'])

    if character && source
      "#{character} (#{source})"
    else
      character || source || first_value(data['member_name'])
    end
  end

  # SauceNAO fields can be arrays or newline-separated lists; take the first entry.
  def first_value(value)
    value = value.first if value.is_a?(Array)
    value.to_s.split("\n").first.to_s.strip.presence
  end
end
