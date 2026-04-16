class Profile < ApplicationRecord
  VALID_TYPES = %w[band venue producer].freeze

  belongs_to :user
  has_one_attached :logo

  validates :profile_type, presence: true,
            inclusion: { in: VALID_TYPES, message: :invalid_profile_type }
  validates :name, presence: true
  validates :city, presence: true

  after_save :enqueue_geocoding_if_city_changed
  after_commit :broadcast_map_changes

  private

  def enqueue_geocoding_if_city_changed
    return unless saved_change_to_city?

    if Rails.env.development?
      GeocodingJob.perform_now(id)
    else
      GeocodingJob.perform_later(id)
    end
  end

  def broadcast_map_changes
    visible_with_coords = map_visible? && latitude.present? && longitude.present?

    if saved_change_to_map_visible?
      if map_visible?
        MapBroadcastService.broadcast_pin_added(self) if visible_with_coords
      else
        MapBroadcastService.broadcast_pin_removed(id)
      end
    elsif visible_with_coords && (saved_change_to_name? || saved_change_to_music_genre? ||
                                    saved_change_to_latitude? || saved_change_to_longitude?)
      MapBroadcastService.broadcast_pin_updated(self)
    end
  end
end
