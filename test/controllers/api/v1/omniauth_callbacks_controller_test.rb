require "test_helper"

module Api
  module V1
    class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
      def setup
        OmniAuth.config.test_mode = true
      end

      def teardown
        OmniAuth.config.mock_auth[:google_oauth2] = nil
        OmniAuth.config.mock_auth[:facebook] = nil
      end

      def google_auth_hash(uid: "123456", email: "user@gmail.com")
        OmniAuth::AuthHash.new({
          provider: "google_oauth2",
          uid: uid,
          info: { email: email, name: "Test User" }
        })
      end

      def facebook_auth_hash(uid: "654321", email: "user@facebook.com")
        OmniAuth::AuthHash.new({
          provider: "facebook",
          uid: uid,
          info: { email: email, name: "Facebook User" }
        })
      end

      # ── GOOGLE OAUTH ───────────────────────────────────────────────────────

      test "novo usuário via Google retorna 201 com token e cria usuário" do
        OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash

        assert_difference "User.count", 1 do
          get "/auth/google_oauth2/callback"
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert json["token"].present?, "token deve estar no body"
        assert_equal "user@gmail.com", json["user"]["email"]
        assert response.headers["Authorization"].start_with?("Bearer "), "Authorization header deve estar presente"
      end

      test "usuário existente via Google retorna 200 sem duplicação" do
        OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash

        # Cria o usuário na primeira chamada
        get "/auth/google_oauth2/callback"
        assert_response :created

        # Segunda chamada: mesmo usuário, deve retornar 200 sem criar novo
        OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash
        assert_no_difference "User.count" do
          get "/auth/google_oauth2/callback"
        end

        assert_response :ok
        json = JSON.parse(response.body)
        assert json["token"].present?
        assert_equal "user@gmail.com", json["user"]["email"]
      end

      test "novo usuário via Facebook retorna 201 com token" do
        OmniAuth.config.mock_auth[:facebook] = facebook_auth_hash

        assert_difference "User.count", 1 do
          get "/auth/facebook/callback"
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert json["token"].present?
        assert_equal "user@facebook.com", json["user"]["email"]
        assert response.headers["Authorization"].start_with?("Bearer ")
      end

      # ── FALHA OAUTH ────────────────────────────────────────────────────────

      test "falha OAuth retorna 422 com code oauth_failed" do
        OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

        get "/auth/google_oauth2/callback"

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "oauth_failed", json["code"]
        assert_equal "Autenticação OAuth falhou", json["error"]
      end
    end
  end
end
