module Api
  module V1
    class PasswordsController < Devise::PasswordsController
      respond_to :json

      # Devise::PasswordsController herda de DeviseController que tem verify_signed_out_user
      # que chama respond_to — não existe em ActionController::API. Igual ao SessionsController.
      skip_before_action :verify_signed_out_user, raise: false

      def create
        # Sempre tenta enviar, mas sempre retorna 200 — previne enumeração de e-mails
        resource_class.send_reset_password_instructions(resource_params)
        render json: { message: "Se o e-mail estiver cadastrado, você receberá as instruções de recuperação" },
               status: :ok
      end

      def update
        self.resource = resource_class.reset_password_by_token(resource_params)
        if resource.errors.empty?
          render json: { message: "Senha redefinida com sucesso" }, status: :ok
        else
          render json: { error: "Token inválido ou expirado", code: "invalid_reset_token" },
                 status: :unprocessable_entity
        end
      end

      private

      def resource_params
        params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
      end
    end
  end
end
