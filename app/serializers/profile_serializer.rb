class ProfileSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json
    {
      id: @profile.id,
      profile_type: @profile.profile_type,
      name: @profile.name,
      bio: @profile.bio,
      city: @profile.city,
      music_genre: @profile.music_genre,
      map_visible: @profile.map_visible,
      latitude: @profile.latitude,
      longitude: @profile.longitude,
      user_id: @profile.user_id,
      created_at: @profile.created_at,
      updated_at: @profile.updated_at
    }
  end
end
