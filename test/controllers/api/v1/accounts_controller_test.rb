require "test_helper"

module Api
  module V1
    class AccountsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @user = User.create!(
          email: "banda@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms_accepted: true
        )
      end

      def login
        post "/api/v1/auth/login",
             params: { user: { email: @user.email, password: "password123" } },
             as: :json
        JSON.parse(response.body)["token"]
      end

      test "exclusao com JWT valido retorna 200 e remove usuario do banco" do
        token = login

        assert_difference "User.count", -1 do
          delete "/api/v1/account",
                 headers: { "Authorization" => "Bearer #{token}" },
                 as: :json
        end

        assert_response :ok
        json = JSON.parse(response.body)
        assert json["message"].present?
        assert_nil User.find_by(id: @user.id)
      end

      test "token invalido apos exclusao retorna 401" do
        token = login

        delete "/api/v1/account",
               headers: { "Authorization" => "Bearer #{token}" },
               as: :json

        assert_response :ok

        # Tentar usar o mesmo token em outro endpoint autenticado — usuário não existe mais
        # (usamos o mesmo endpoint pois não há outros disponíveis ainda no Epic 1)
        delete "/api/v1/account",
               headers: { "Authorization" => "Bearer #{token}" },
               as: :json

        assert_response :unauthorized
      end

      test "exclusao sem JWT retorna 401" do
        delete "/api/v1/account", as: :json

        assert_response :unauthorized
      end
    end
  end
end
