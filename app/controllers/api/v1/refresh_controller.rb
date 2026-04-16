module Api
  module V1
    class RefreshController < ApplicationController
      skip_before_action :authenticate_user!

      def create
        token_value = cookies.signed[:refresh_token]
        refresh_token = token_value && RefreshToken.active.find_by(token: token_value)

        unless refresh_token
          render json: { error: "Refresh token inválido ou expirado", code: "invalid_refresh_token" },
                 status: :unauthorized
          return
        end

        user = refresh_token.user
        refresh_token.revoke!

        new_refresh_token = RefreshToken.generate_for(user)
        set_refresh_cookie(new_refresh_token.token)

        jwt_token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
        response.headers["Authorization"] = "Bearer #{jwt_token}"
        render json: { token: jwt_token, user: { id: user.id, email: user.email } }, status: :ok
      end

      private

      def set_refresh_cookie(token)
        cookies.signed[:refresh_token] = {
          value: token,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :strict,
          expires: RefreshToken::EXPIRY.from_now
        }
      end
    end
  end
end
