class MapPinSerializer
  include Rails.application.routes.url_helpers

  def initialize(profile)
    @profile = profile
  end

  def as_json
    {
      id: @profile.id,
      name: @profile.name,
      profile_type: @profile.profile_type,
      latitude: @profile.latitude,
      longitude: @profile.longitude,
      city: @profile.city,
      music_genre: @profile.music_genre,
      logo_url: logo_url_for(@profile)
    }
  end

  private

  def logo_url_for(profile)
    return nil unless profile.logo.attached?

    rails_blob_path(profile.logo, only_path: true)
  end
end
