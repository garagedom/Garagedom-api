class MapBroadcastService
  def self.broadcast_pin_added(profile)
    ActionCable.server.broadcast("map", {
      type: "pin_added",
      pin: MapPinSerializer.new(profile).as_json
    })
  end

  def self.broadcast_pin_removed(profile_id)
    ActionCable.server.broadcast("map", {
      type: "pin_removed",
      pin_id: profile_id
    })
  end

  def self.broadcast_pin_updated(profile)
    ActionCable.server.broadcast("map", {
      type: "pin_updated",
      pin: MapPinSerializer.new(profile).as_json
    })
  end
end
