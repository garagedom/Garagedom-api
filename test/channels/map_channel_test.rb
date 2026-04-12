require "test_helper"

class MapChannelTest < ActionCable::Channel::TestCase
  setup do
    @user = User.create!(email: "cable@test.com", password: "password123", terms_accepted: true)

    band_user = User.create!(email: "band@cable.com", password: "pass123", terms_accepted: true)
    @profile = FactoryBot.create(:profile,
      user: band_user,
      profile_type: "band",
      name: "Banda Cable",
      city: "Jundiaí",
      map_visible: true,
      latitude: -23.1896,
      longitude: -46.8956)
  end

  test "subscribe autenticado inicia stream do mapa" do
    stub_connection current_user: @user
    subscribe
    assert subscription.confirmed?
    assert_has_stream "map"
  end

  test "subscribe sem usuário é rejeitado" do
    stub_connection current_user: nil
    subscribe
    assert subscription.rejected?
  end

  test "broadcast_pin_added envia tipo pin_added com pin enriquecido" do
    stub_connection current_user: @user
    subscribe

    expected_pin = MapPinSerializer.new(@profile).as_json
    assert_broadcast_on("map", { type: "pin_added", pin: expected_pin }) do
      MapBroadcastService.broadcast_pin_added(@profile)
    end
  end

  test "broadcast_pin_added envia os 8 campos enriquecidos no payload" do
    stub_connection current_user: @user
    subscribe

    assert_broadcasts("map", 1) do
      MapBroadcastService.broadcast_pin_added(@profile)
    end

    broadcast = broadcasts("map").last
    data = ActiveSupport::JSON.decode(broadcast)
    pin = data["pin"]

    assert_equal "pin_added", data["type"]
    assert_equal %w[city id latitude logo_url longitude music_genre name profile_type], pin.keys.sort
    assert_equal @profile.id, pin["id"]
    assert_equal "Jundiaí", pin["city"]
    assert_nil pin["logo_url"]
  end

  test "broadcast_pin_removed envia pin_id" do
    stub_connection current_user: @user
    subscribe

    assert_broadcast_on("map", { type: "pin_removed", pin_id: 42 }) do
      MapBroadcastService.broadcast_pin_removed(42)
    end
  end

  test "broadcast_pin_updated envia tipo pin_updated com pin enriquecido" do
    stub_connection current_user: @user
    subscribe

    expected_pin = MapPinSerializer.new(@profile).as_json
    assert_broadcast_on("map", { type: "pin_updated", pin: expected_pin }) do
      MapBroadcastService.broadcast_pin_updated(@profile)
    end
  end
end
