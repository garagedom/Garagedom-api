require "test_helper"

module Api
  module V1
    class RegistrationsControllerTest < ActionDispatch::IntegrationTest
      def valid_params
        {
          user: {
            email: "banda@example.com",
            password: "password123",
            password_confirmation: "password123",
            terms_accepted: true
          }
        }
      end

      test "registro bem-sucedido retorna 201 com token e user" do
        post "/api/v1/auth/register", params: valid_params, as: :json

        assert_response :created
        json = JSON.parse(response.body)
        assert json["token"].present?, "token deve estar no body"
        assert_equal "banda@example.com", json["user"]["email"]
        assert json["user"]["id"].present?
        assert response.headers["Authorization"].start_with?("Bearer "), "Authorization header deve estar presente"
      end

      test "registro cria usuário no banco" do
        assert_difference "User.count", 1 do
          post "/api/v1/auth/register", params: valid_params, as: :json
        end
      end

      test "token do header e do body são iguais" do
        post "/api/v1/auth/register", params: valid_params, as: :json

        json = JSON.parse(response.body)
        header_token = response.headers["Authorization"].split(" ").last
        assert_equal json["token"], header_token
      end

      test "jti é definido automaticamente no registro" do
        post "/api/v1/auth/register", params: valid_params, as: :json

        user = User.find_by(email: "banda@example.com")
        assert_not_empty user.jti, "jti deve ser preenchido pelo JTIMatcher before_create"
      end

      test "terms_accepted false retorna 422 com code terms_required" do
        post "/api/v1/auth/register",
             params: valid_params.deep_merge(user: { terms_accepted: false }),
             as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "terms_required", json["code"]
        assert json["error"].present?
      end

      test "terms_accepted ausente retorna 422 com code terms_required" do
        params = { user: { email: "a@b.com", password: "password123", password_confirmation: "password123" } }
        post "/api/v1/auth/register", params: params, as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "terms_required", json["code"]
      end

      test "email duplicado retorna 422 com code email_taken" do
        User.create!(email: "banda@example.com", password: "password123",
                     password_confirmation: "password123", terms_accepted: true)

        post "/api/v1/auth/register", params: valid_params, as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "email_taken", json["code"]
        assert_equal "E-mail já cadastrado", json["error"]
      end

      test "senha muito curta retorna 422 com code unprocessable_entity" do
        post "/api/v1/auth/register",
             params: valid_params.deep_merge(user: { password: "curta", password_confirmation: "curta" }),
             as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "unprocessable_entity", json["code"]
      end

      test "email ausente retorna 422" do
        post "/api/v1/auth/register",
             params: valid_params.deep_merge(user: { email: "" }),
             as: :json

        assert_response :unprocessable_entity
      end

      test "registro com erro não cria usuário no banco" do
        assert_no_difference "User.count" do
          post "/api/v1/auth/register",
               params: valid_params.deep_merge(user: { terms_accepted: false }),
               as: :json
        end
      end
    end
  end
end
