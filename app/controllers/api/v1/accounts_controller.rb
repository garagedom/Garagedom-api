module Api
  module V1
    class AccountsController < ApplicationController
      def destroy
        current_user.destroy
        render json: { message: "Conta excluída permanentemente" }, status: :ok
      end
    end
  end
end
