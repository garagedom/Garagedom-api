require "test_helper"

module Api
  module V1
    class ProfilesControllerTest < ActionDispatch::IntegrationTest
      include ActiveJob::TestHelper

      setup do
        @user = User.create!(
          email: "band@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms_accepted: true
        )
        @token = jwt_token_for(@user)
      end

      # ── POST /api/v1/profiles ──────────────────────────────────────────────

      test "cria perfil com dados válidos e retorna 201" do
        assert_enqueued_with(job: GeocodingJob) do
          post "/api/v1/profiles",
               params: { profile_type: "band", name: "Banda Rock", city: "Jundiaí", bio: "Bio", music_genre: "Rock" },
               headers: auth_headers(@token),
               as: :json
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal "band", json["profile_type"]
        assert_equal "Banda Rock", json["name"]
        assert_equal "Jundiaí", json["city"]
        assert json["map_visible"]
        assert_nil json["latitude"]
        assert_nil json["longitude"]
      end

      test "cria perfil com profile_type venue" do
        post "/api/v1/profiles",
             params: { profile_type: "venue", name: "Casa de Shows", city: "SP" },
             headers: auth_headers(@token),
             as: :json

        assert_response :created
        assert_equal "venue", JSON.parse(response.body)["profile_type"]
      end

      test "cria perfil com profile_type producer" do
        post "/api/v1/profiles",
             params: { profile_type: "producer", name: "Produtor Top", city: "RJ" },
             headers: auth_headers(@token),
             as: :json

        assert_response :created
        assert_equal "producer", JSON.parse(response.body)["profile_type"]
      end

      test "retorna 422 com profile_type inválido" do
        post "/api/v1/profiles",
             params: { profile_type: "admin", name: "Teste", city: "SP" },
             headers: auth_headers(@token),
             as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "Tipo de perfil inválido", json["error"]
        assert_equal "invalid_profile_type", json["code"]
      end

      test "retorna 422 quando profile_type está ausente" do
        post "/api/v1/profiles",
             params: { name: "Teste", city: "SP" },
             headers: auth_headers(@token),
             as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "invalid_profile_type", json["code"]
      end

      test "retorna 422 quando usuário já possui perfil" do
        FactoryBot.create(:profile, user: @user)

        post "/api/v1/profiles",
             params: { profile_type: "band", name: "Segundo Perfil", city: "SP" },
             headers: auth_headers(@token),
             as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal "Usuário já possui perfil", json["error"]
        assert_equal "profile_already_exists", json["code"]
      end

      test "retorna 401 sem JWT" do
        post "/api/v1/profiles",
             params: { profile_type: "band", name: "Banda", city: "SP" },
             as: :json

        assert_response :unauthorized
      end

      test "retorna 422 sem name" do
        post "/api/v1/profiles",
             params: { profile_type: "band", city: "SP" },
             headers: auth_headers(@token),
             as: :json

        assert_response :unprocessable_entity
      end

      test "retorna 422 sem city" do
        post "/api/v1/profiles",
             params: { profile_type: "band", name: "Banda" },
             headers: auth_headers(@token),
             as: :json

        assert_response :unprocessable_entity
      end

      # ── GET /api/v1/profiles/:id (Story 2.4) ──────────────────────────────

      test "visualiza perfil próprio e retorna 200" do
        profile = FactoryBot.create(:profile, user: @user)

        get "/api/v1/profiles/#{profile.id}",
            headers: auth_headers(@token),
            as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal profile.id, json["id"]
        assert_equal "band", json["profile_type"]
        assert_equal profile.name, json["name"]
        assert_equal profile.city, json["city"]
      end

      test "visualiza perfil de outro usuário e retorna 200" do
        outro_user = User.create!(email: "outro2@example.com", password: "pass123", terms_accepted: true)
        outro_profile = FactoryBot.create(:profile, user: outro_user, profile_type: "venue", name: "Casa X")

        get "/api/v1/profiles/#{outro_profile.id}",
            headers: auth_headers(@token),
            as: :json

        assert_response :ok
        assert_equal "venue", JSON.parse(response.body)["profile_type"]
      end

      test "retorna 404 para perfil inexistente" do
        get "/api/v1/profiles/999999",
            headers: auth_headers(@token),
            as: :json

        assert_response :not_found
        assert_equal "not_found", JSON.parse(response.body)["code"]
      end

      test "retorna 401 ao visualizar sem JWT" do
        profile = FactoryBot.create(:profile, user: @user)

        get "/api/v1/profiles/#{profile.id}", as: :json

        assert_response :unauthorized
      end

      # ── PATCH /api/v1/profiles/:id ─────────────────────────────────────────

      test "edita perfil com dados válidos e retorna 200" do
        profile = FactoryBot.create(:profile, user: @user, city: "Jundiaí")

        patch "/api/v1/profiles/#{profile.id}",
              params: { name: "Novo Nome", bio: "Nova bio" },
              headers: auth_headers(@token),
              as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal "Novo Nome", json["name"]
        assert_equal "Nova bio", json["bio"]
      end

      test "edita city e enfileira GeocodingJob" do
        profile = FactoryBot.create(:profile, user: @user, city: "Jundiaí")

        assert_enqueued_with(job: GeocodingJob) do
          patch "/api/v1/profiles/#{profile.id}",
                params: { city: "Campinas" },
                headers: auth_headers(@token),
                as: :json
        end

        assert_response :ok
        assert_equal "Campinas", JSON.parse(response.body)["city"]
      end

      test "edita sem alterar city e não enfileira GeocodingJob" do
        profile = FactoryBot.create(:profile, user: @user, city: "Jundiaí")

        assert_no_enqueued_jobs(only: GeocodingJob) do
          patch "/api/v1/profiles/#{profile.id}",
                params: { name: "Nome Atualizado" },
                headers: auth_headers(@token),
                as: :json
        end

        assert_response :ok
      end

      test "retorna 403 ao editar perfil de outro usuário" do
        outro_user = User.create!(email: "outro@example.com", password: "pass123", terms_accepted: true)
        profile = FactoryBot.create(:profile, user: outro_user)

        patch "/api/v1/profiles/#{profile.id}",
              params: { name: "Invasor" },
              headers: auth_headers(@token),
              as: :json

        assert_response :forbidden
        json = JSON.parse(response.body)
        assert_equal "Acesso negado", json["error"]
        assert_equal "forbidden", json["code"]
      end

      test "retorna 401 ao editar sem JWT" do
        profile = FactoryBot.create(:profile, user: @user)

        patch "/api/v1/profiles/#{profile.id}",
              params: { name: "Teste" },
              as: :json

        assert_response :unauthorized
      end

      test "retorna 422 ao editar com name vazio" do
        profile = FactoryBot.create(:profile, user: @user)

        patch "/api/v1/profiles/#{profile.id}",
              params: { name: "" },
              headers: auth_headers(@token),
              as: :json

        assert_response :unprocessable_entity
      end

      test "retorna 404 ao editar perfil inexistente" do
        patch "/api/v1/profiles/999999",
              params: { name: "Teste" },
              headers: auth_headers(@token),
              as: :json

        assert_response :not_found
        assert_equal "not_found", JSON.parse(response.body)["code"]
      end

      # ── PATCH map_visible (Story 2.3) ─────────────────────────────────────

      test "oculta perfil do mapa com map_visible false" do
        profile = FactoryBot.create(:profile, user: @user, map_visible: true)

        patch "/api/v1/profiles/#{profile.id}",
              params: { map_visible: false },
              headers: auth_headers(@token),
              as: :json

        assert_response :ok
        assert_equal false, JSON.parse(response.body)["map_visible"]
        assert_equal false, profile.reload.map_visible
      end

      test "reativa perfil no mapa com map_visible true" do
        profile = FactoryBot.create(:profile, user: @user, map_visible: false)

        patch "/api/v1/profiles/#{profile.id}",
              params: { map_visible: true },
              headers: auth_headers(@token),
              as: :json

        assert_response :ok
        assert_equal true, JSON.parse(response.body)["map_visible"]
        assert_equal true, profile.reload.map_visible
      end

      test "não permite alterar profile_type via update" do
        profile = FactoryBot.create(:profile, user: @user, profile_type: "band")

        patch "/api/v1/profiles/#{profile.id}",
              params: { profile_type: "venue" },
              headers: auth_headers(@token),
              as: :json

        assert_response :ok
        assert_equal "band", JSON.parse(response.body)["profile_type"]
      end

      private

      def jwt_token_for(user)
        post "/api/v1/auth/login",
             params: { user: { email: user.email, password: "password123" } },
             as: :json
        JSON.parse(response.body)["token"]
      end

      def auth_headers(token)
        { "Authorization" => "Bearer #{token}" }
      end
    end
  end
end
