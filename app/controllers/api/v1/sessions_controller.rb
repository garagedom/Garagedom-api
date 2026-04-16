module Api
  module V1
    class SessionsController < Devise::SessionsController
      include ActionController::Cookies

      respond_to :json

      # Devise::SessionsController#verify_signed_out_user chama `respond_to` (content negotiation)
      # que não existe em ActionController::API. Skippamos e gerenciamos auth manualmente.
      skip_before_action :verify_signed_out_user, raise: false

      def create
        user = User.find_by(email: login_params[:email])
        if user&.valid_password?(login_params[:password])
          token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
          refresh_token = RefreshToken.generate_for(user)
          set_refresh_cookie(refresh_token.token)
          response.headers["Authorization"] = "Bearer #{token}"
          render json: { token: token, user: { id: user.id, email: user.email } }, status: :ok
        else
          render json: { error: "E-mail ou senha inválidos", code: "invalid_credentials" },
                 status: :unauthorized
        end
      end

      def destroy
        unless current_user
          render json: { error: "Token inválido ou ausente", code: "unauthorized" },
                 status: :unauthorized
          return
        end

        token_value = cookies.signed[:refresh_token]
        if token_value
          RefreshToken.find_by(token: token_value)&.revoke!
          cookies.delete(:refresh_token)
        end

        render json: { message: "Logout realizado com sucesso" }, status: :ok
      end

      private

      def login_params
        params.require(:user).permit(:email, :password)
      end

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
