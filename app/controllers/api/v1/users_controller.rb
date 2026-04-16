module Api
  module V1
    class UsersController < ApplicationController
      def me
        render json: { id: current_user.id, email: current_user.email }, status: :ok
      end
    end
  end
end
