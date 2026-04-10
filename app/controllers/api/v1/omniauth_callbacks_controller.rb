module Api
  module V1
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      skip_before_action :verify_signed_out_user, raise: false

      def google_oauth2
        handle_omniauth
      end

      def facebook
        handle_omniauth
      end

      private

      def handle_omniauth
        auth = request.env["omniauth.auth"]
        if auth.blank?
          render json: { error: "Autenticação OAuth falhou", code: "oauth_failed" },
                 status: :unprocessable_entity
          return
        end

        user = User.from_omniauth(auth)
        if user.nil?
          render json: { error: "Autenticação OAuth falhou", code: "oauth_failed" },
                 status: :unprocessable_entity
          return
        end

        status_code = user.previously_new_record? ? :created : :ok
        token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
        response.headers["Authorization"] = "Bearer #{token}"
        render json: { token: token, user: { id: user.id, email: user.email } },
               status: status_code
      end
    end
  end
end
