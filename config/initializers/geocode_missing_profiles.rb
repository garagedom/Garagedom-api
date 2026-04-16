if Rails.env.production?
  Rails.application.config.after_initialize do
    missing = Profile.where(latitude: nil).or(Profile.where(longitude: nil))
    missing.find_each { |p| GeocodingJob.perform_later(p.id) }
  end
end
