require "test_helper"

module Api
  module V1
    class MapControllerTest < ActionDispatch::IntegrationTest
      setup do
        @requester = User.create!(email: "requester@example.com", password: "password123", terms_accepted: true)
        @token = jwt_token_for(@requester)

        # Perfil band com coordenadas — deve aparecer no mapa
        band_user = User.create!(email: "band@map.com", password: "pass123", terms_accepted: true)
        @band = FactoryBot.create(:profile,
          user: band_user,
          profile_type: "band",
          name: "Banda Rock",
          city: "Jundiaí",
          map_visible: true,
          latitude: -23.1896,
          longitude: -46.8956)

        # Perfil venue com coordenadas — deve aparecer no mapa
        venue_user = User.create!(email: "venue@map.com", password: "pass123", terms_accepted: true)
        @venue = FactoryBot.create(:profile,
          user: venue_user,
          profile_type: "venue",
          name: "Casa de Shows",
          city: "Rio de Janeiro",
          map_visible: true,
          latitude: -22.9068,
          longitude: -43.1729)

        # Perfil oculto — NÃO deve aparecer
        hidden_user = User.create!(email: "hidden@map.com", password: "pass123", terms_accepted: true)
        @hidden = FactoryBot.create(:profile,
          user: hidden_user,
          profile_type: "band",
          name: "Banda Invisível",
          city: "SP",
          map_visible: false,
          latitude: -23.55,
          longitude: -46.63)

        # Perfil sem coordenadas (geocoding pendente) — NÃO deve aparecer
        no_coords_user = User.create!(email: "nocoords@map.com", password: "pass123", terms_accepted: true)
        @no_coords = FactoryBot.create(:profile,
          user: no_coords_user,
          profile_type: "producer",
          name: "Produtor Sem Coords",
          city: "Campinas",
          map_visible: true,
          latitude: nil,
          longitude: nil)
      end

      # ── GET /api/v1/map/pins ───────────────────────────────────────────────

      test "retorna array de pins visíveis e geocodificados" do
        get "/api/v1/map/pins", headers: auth_headers(@token), as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert_instance_of Array, json

        ids = json.map { |p| p["id"] }
        assert_includes ids, @band.id
        assert_includes ids, @venue.id
        assert_not_includes ids, @hidden.id
        assert_not_includes ids, @no_coords.id
      end

      test "cada pin contém id, name, profile_type, latitude, longitude, city, music_genre e logo_url" do
        get "/api/v1/map/pins", headers: auth_headers(@token), as: :json

        pin = JSON.parse(response.body).find { |p| p["id"] == @band.id }
        assert_not_nil pin
        assert_equal %w[city id latitude logo_url longitude music_genre name profile_type], pin.keys.sort
      end

      test "pin inclui logo_url quando logo está anexado" do
        file = fixture_file_upload("logo.png", "image/png")
        @band.logo.attach(file)
        get "/api/v1/map/pins", headers: auth_headers(@token), as: :json

        pins = JSON.parse(response.body)
        band_pin = pins.find { |p| p["id"] == @band.id }
        assert_not_nil band_pin["logo_url"]
        assert_match(/logo/, band_pin["logo_url"])
      end

      test "pin tem logo_url nulo quando sem logo" do
        get "/api/v1/map/pins", headers: auth_headers(@token), as: :json

        pins = JSON.parse(response.body)
        band_pin = pins.find { |p| p["id"] == @band.id }
        assert_nil band_pin["logo_url"]
      end

      test "pin inclui city e music_genre" do
        get "/api/v1/map/pins", headers: auth_headers(@token), as: :json

        pin = JSON.parse(response.body).find { |p| p["id"] == @band.id }
        assert_equal "Jundiaí", pin["city"]
        assert_equal "Rock", pin["music_genre"]
      end

      test "filtra por profile_type=band" do
        get "/api/v1/map/pins?profile_type=band", headers: auth_headers(@token), as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json.all? { |p| p["profile_type"] == "band" }
        assert_includes json.map { |p| p["id"] }, @band.id
        assert_not_includes json.map { |p| p["id"] }, @venue.id
      end

      test "filtra por profile_type=venue" do
        get "/api/v1/map/pins?profile_type=venue", headers: auth_headers(@token), as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json.all? { |p| p["profile_type"] == "venue" }
        assert_includes json.map { |p| p["id"] }, @venue.id
      end

      test "filtra por city retorna perfis da cidade correta" do
        # venue está em "Rio de Janeiro"
        get "/api/v1/map/pins?city=Rio+de+Janeiro", headers: auth_headers(@token)

        assert_response :ok
        json = JSON.parse(response.body)
        assert_includes json.map { |p| p["id"] }, @venue.id
        assert_not_includes json.map { |p| p["id"] }, @band.id
      end

      test "filtro city é case-insensitive" do
        get "/api/v1/map/pins?city=rio+de+janeiro", headers: auth_headers(@token)

        assert_response :ok
        json = JSON.parse(response.body)
        assert_includes json.map { |p| p["id"] }, @venue.id
      end

      test "retorna array vazio quando nenhum perfil visível geocodificado" do
        Profile.update_all(map_visible: false)

        get "/api/v1/map/pins", headers: auth_headers(@token), as: :json

        assert_response :ok
        assert_equal [], JSON.parse(response.body)
      end

      test "retorna 401 sem JWT" do
        get "/api/v1/map/pins", as: :json

        assert_response :unauthorized
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
