class MapPinSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json
    {
      id: @profile.id,
      name: @profile.name,
      profile_type: @profile.profile_type,
      latitude: @profile.latitude,
      longitude: @profile.longitude
    }
  end
end
