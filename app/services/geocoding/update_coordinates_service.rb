module Geocoding
  class UpdateCoordinatesService
    def initialize(profile)
      @profile = profile
    end

    def call
      results = Geocoder.search(@profile.city)
      return if results.empty?

      @profile.update_columns(
        latitude: results.first.latitude,
        longitude: results.first.longitude
      )
    rescue StandardError => e
      Rails.logger.warn("[GeocodingService] Failed to geocode profile #{@profile.id}: #{e.message}")
    end
  end
end
