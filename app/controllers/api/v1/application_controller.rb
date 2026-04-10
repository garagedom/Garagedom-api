module Api
  module V1
    class ApplicationController < ActionController::API
      before_action :authenticate_user!

      private

      def current_profile
        @current_profile ||= current_user&.profile
      end

      def not_found
        render json: { error: "Recurso não encontrado", code: "not_found" }, status: :not_found
      end

      def bad_request(exception)
        render json: { error: exception.message, code: "bad_request" }, status: :bad_request
      end

      def forbidden
        render json: { error: "Acesso negado", code: "forbidden" }, status: :forbidden
      end

      def unprocessable(message, code = "unprocessable_entity")
        render json: { error: message, code: code }, status: :unprocessable_entity
      end

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request
    end
  end
end
