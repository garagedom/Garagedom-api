class Profile < ApplicationRecord
  VALID_TYPES = %w[band venue producer].freeze

  belongs_to :user

  validates :profile_type, presence: true,
            inclusion: { in: VALID_TYPES, message: :invalid_profile_type }
  validates :name, presence: true
  validates :city, presence: true

  after_save :enqueue_geocoding_if_city_changed

  private

  def enqueue_geocoding_if_city_changed
    GeocodingJob.perform_later(id) if saved_change_to_city?
  end
end
