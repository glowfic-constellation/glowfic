Geocoder.configure(
  cache: Geocoder::CacheStore::Generic.new(Rails.cache, {}),
  cache_options: { expiration: 3.days },
  ip_lookup: :ipinfo_io_lite,
  api_key: ENV.fetch("IPINFO_API_KEY", ""),
)
