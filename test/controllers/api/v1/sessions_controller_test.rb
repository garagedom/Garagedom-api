require "test_helper"

module Api
  module V1
    class SessionsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @user = User.create!(
          email: "banda@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms_accepted: true
        )
      end

      def login_params(email: @user.email, password: "password123")
        { user: { email: email, password: password } }
      end

      # ── LOGIN ──────────────────────────────────────────────────────────────

      test "login bem-sucedido retorna 200 com token e user" do
        post "/api/v1/auth/login", params: login_params, as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json["token"].present?, "token deve estar no body"
        assert_equal @user.email, json["user"]["email"]
        assert_equal @user.id, json["user"]["id"]
        assert response.headers["Authorization"].start_with?("Bearer "), "Authorization header deve estar presente"
      end

      test "token no header e no body são iguais" do
        post "/api/v1/auth/login", params: login_params, as: :json

        json = JSON.parse(response.body)
        header_token = response.headers["Authorization"].split(" ").last
        assert_equal json["token"], header_token
      end

      test "login com senha incorreta retorna 401" do
        post "/api/v1/auth/login", params: login_params(password: "senha_errada"), as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "invalid_credentials", json["code"]
        assert_equal "E-mail ou senha inválidos", json["error"]
      end

      test "login com email inexistente retorna 401" do
        post "/api/v1/auth/login", params: login_params(email: "naoexiste@example.com"), as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "invalid_credentials", json["code"]
      end

      test "login com email e senha ausentes retorna 400 ou 401" do
        post "/api/v1/auth/login", params: { user: { email: "", password: "" } }, as: :json

        assert_includes [400, 401], response.status
      end

      # ── LOGOUT ─────────────────────────────────────────────────────────────

      test "logout com token válido retorna 200" do
        post "/api/v1/auth/login", params: login_params, as: :json
        token = JSON.parse(response.body)["token"]

        delete "/api/v1/auth/logout",
               headers: { "Authorization" => "Bearer #{token}" },
               as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json["message"].present?
      end

      test "token é inválido após logout" do
        post "/api/v1/auth/login", params: login_params, as: :json
        token = JSON.parse(response.body)["token"]

        delete "/api/v1/auth/logout",
               headers: { "Authorization" => "Bearer #{token}" },
               as: :json

        assert_response :ok

        # Segunda tentativa de logout com o mesmo token — deve falhar
        delete "/api/v1/auth/logout",
               headers: { "Authorization" => "Bearer #{token}" },
               as: :json

        assert_response :unauthorized
      end

      test "logout sem token retorna 401" do
        delete "/api/v1/auth/logout", as: :json

        assert_response :unauthorized
      end

      test "logout sem Authorization header retorna 401" do
        delete "/api/v1/auth/logout", headers: {}, as: :json

        assert_response :unauthorized
      end
    end
  end
end
