require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = FactoryBot.create(:user, email: "band@test.com", password: "password123", terms_accepted: true)
  end

  test "válido com atributos corretos" do
    profile = Profile.new(user: @user, profile_type: "band", name: "Banda X", city: "Jundiaí")
    assert profile.valid?
  end

  test "inválido sem profile_type" do
    profile = Profile.new(user: @user, name: "Banda X", city: "Jundiaí")
    assert_not profile.valid?
    assert profile.errors[:profile_type].present?
  end

  test "inválido com profile_type fora de band/venue/producer" do
    profile = Profile.new(user: @user, profile_type: "admin", name: "Banda X", city: "Jundiaí")
    assert_not profile.valid?
    assert profile.errors[:profile_type].present?
  end

  test "inválido sem name" do
    profile = Profile.new(user: @user, profile_type: "band", city: "Jundiaí")
    assert_not profile.valid?
    assert profile.errors[:name].present?
  end

  test "inválido sem city" do
    profile = Profile.new(user: @user, profile_type: "band", name: "Banda X")
    assert_not profile.valid?
    assert profile.errors[:city].present?
  end

  test "map_visible é true por padrão" do
    profile = FactoryBot.create(:profile, user: @user)
    assert profile.map_visible
  end

  test "enfileira GeocodingJob após salvar com city" do
    assert_enqueued_with(job: GeocodingJob) do
      FactoryBot.create(:profile, user: @user, city: "Campinas")
    end
  end

  test "não enfileira GeocodingJob se city não foi alterado" do
    profile = FactoryBot.create(:profile, user: @user, city: "Jundiaí")
    assert_no_enqueued_jobs(only: GeocodingJob) do
      profile.update!(name: "Novo Nome")
    end
  end

  test "aceita profile_type band, venue e producer" do
    %w[band venue producer].each_with_index do |type, i|
      user = FactoryBot.create(:user, email: "type#{i}@test.com", password: "pass123", terms_accepted: true)
      profile = Profile.new(user: user, profile_type: type, name: "Teste", city: "SP")
      assert profile.valid?, "profile_type '#{type}' deveria ser válido"
    end
  end
end
