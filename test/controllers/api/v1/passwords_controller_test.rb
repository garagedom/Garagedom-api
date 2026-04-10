require "test_helper"

module Api
  module V1
    class PasswordsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @user = User.create!(
          email: "banda@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms_accepted: true
        )
        ActionMailer::Base.deliveries.clear
      end

      # ── SOLICITAR RESET ────────────────────────────────────────────────────

      test "solicitar reset com email cadastrado retorna 200 e envia email" do
        assert_difference "ActionMailer::Base.deliveries.size", 1 do
          post "/api/v1/auth/password",
               params: { user: { email: @user.email } },
               as: :json
        end

        assert_response :ok
        json = JSON.parse(response.body)
        assert json["message"].present?

        email = ActionMailer::Base.deliveries.last
        assert_equal [@user.email], email.to
      end

      test "solicitar reset com email NAO cadastrado retorna 200 (sem enumeracao)" do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          post "/api/v1/auth/password",
               params: { user: { email: "naoexiste@example.com" } },
               as: :json
        end

        assert_response :ok
        json = JSON.parse(response.body)
        assert json["message"].present?
      end

      # ── REDEFINIR SENHA ────────────────────────────────────────────────────

      test "redefinir senha com token valido retorna 200" do
        token = @user.send_reset_password_instructions

        put "/api/v1/auth/password",
            params: {
              user: {
                reset_password_token: token,
                password: "nova_senha_123",
                password_confirmation: "nova_senha_123"
              }
            },
            as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json["message"].present?
      end

      test "nova senha funciona apos reset" do
        token = @user.send_reset_password_instructions

        put "/api/v1/auth/password",
            params: {
              user: {
                reset_password_token: token,
                password: "nova_senha_123",
                password_confirmation: "nova_senha_123"
              }
            },
            as: :json

        assert_response :ok

        # Login com nova senha deve funcionar
        post "/api/v1/auth/login",
             params: { user: { email: @user.email, password: "nova_senha_123" } },
             as: :json

        assert_response :ok
        assert JSON.parse(response.body)["token"].present?
      end

      test "redefinir senha com token invalido retorna 422" do
        put "/api/v1/auth/password",
            params: {
              user: {
                reset_password_token: "token_invalido",
                password: "nova_senha_123",
                password_confirmation: "nova_senha_123"
              }
            },
            as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "invalid_reset_token", json["code"]
        assert_equal "Token inválido ou expirado", json["error"]
      end

      test "redefinir senha com token expirado retorna 422" do
        token = @user.send_reset_password_instructions
        @user.update!(reset_password_sent_at: 7.hours.ago)

        put "/api/v1/auth/password",
            params: {
              user: {
                reset_password_token: token,
                password: "nova_senha_123",
                password_confirmation: "nova_senha_123"
              }
            },
            as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "invalid_reset_token", json["code"]
      end
    end
  end
end
