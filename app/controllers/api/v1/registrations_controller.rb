module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      def create
        build_resource(sign_up_params)
        resource.save
        if resource.persisted?
          token, _payload = Warden::JWTAuth::UserEncoder.new.call(resource, :user, nil)
          response.headers["Authorization"] = "Bearer #{token}"
          render json: { token: token, user: { id: resource.id, email: resource.email } },
                 status: :created
        else
          render_registration_errors
        end
      end

      private

      def sign_up_params
        params.require(:user).permit(:email, :password, :password_confirmation, :terms_accepted)
      end

      def render_registration_errors
        if resource.errors[:terms_accepted].present?
          render json: { error: "Termos de uso devem ser aceitos", code: "terms_required" },
                 status: :unprocessable_entity
        elsif resource.errors[:email].any? { |e| e.include?("taken") }
          render json: { error: "E-mail já cadastrado", code: "email_taken" },
                 status: :unprocessable_entity
        else
          render json: { error: resource.errors.full_messages.first, code: "unprocessable_entity" },
                 status: :unprocessable_entity
        end
      end
    end
  end
end
