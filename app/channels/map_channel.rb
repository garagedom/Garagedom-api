class MapChannel < ApplicationCable::Channel
  def subscribed
    if current_user
      stream_from "map"
    else
      reject
    end
  end

  def unsubscribed
    # cleanup automático pelo ActionCable
  end
end
