module Api
  module V1
    class ProfilesController < ApplicationController
      def create
        return unprocessable("Usuário já possui perfil", "profile_already_exists") if current_profile.present?

        profile = current_user.build_profile(profile_params)

        if profile.save
          render json: ProfileSerializer.new(profile).as_json, status: :created
        elsif profile.errors[:profile_type].present?
          unprocessable("Tipo de perfil inválido", "invalid_profile_type")
        else
          render json: { error: profile.errors.full_messages.first, code: "unprocessable_entity" },
                 status: :unprocessable_entity
        end
      end

      def show
        profile = Profile.find(params[:id])
        render json: ProfileSerializer.new(profile).as_json, status: :ok
      end

      def update
        profile = Profile.find(params[:id])
        return forbidden unless profile.user_id == current_user.id

        if profile.update(update_params)
          render json: ProfileSerializer.new(profile).as_json, status: :ok
        else
          render json: { error: profile.errors.full_messages.first, code: "unprocessable_entity" },
                 status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.permit(:profile_type, :name, :city, :bio, :music_genre)
      end

      def update_params
        params.permit(:name, :city, :bio, :music_genre, :map_visible)
      end
    end
  end
end
