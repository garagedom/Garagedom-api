class GeocodingJob < ApplicationJob
  queue_as :default

  def perform(profile_id)
    profile = Profile.find_by(id: profile_id)
    return unless profile

    Geocoding::UpdateCoordinatesService.new(profile).call
  end
end
