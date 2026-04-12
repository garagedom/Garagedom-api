module Api
  module V1
    class MapController < ApplicationController
      def pins
        profiles = Profile.where(map_visible: true).where.not(latitude: nil, longitude: nil).with_attached_logo
        profiles = profiles.where(profile_type: params[:profile_type]) if params[:profile_type].present?
        profiles = profiles.where("LOWER(city) = LOWER(?)", params[:city]) if params[:city].present?
        render json: profiles.map { |p| MapPinSerializer.new(p).as_json }, status: :ok
      end
    end
  end
end
