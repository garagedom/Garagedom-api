module Api
  module V1
    class UsersController < ApplicationController
      def me
        render json: {
          id: current_user.id,
          email: current_user.email,
          profile_id: current_profile&.id,
          profile_type: current_profile&.profile_type,
        }, status: :ok
      end
    end
  end
end
