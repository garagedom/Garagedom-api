FactoryBot.define do
  factory :profile do
    association :user
    profile_type { "band" }
    name { "Banda Teste" }
    city { "Jundiaí" }
    bio { "Uma banda incrível" }
    music_genre { "Rock" }
    map_visible { true }

    trait :venue do
      profile_type { "venue" }
      name { "Casa de Shows Teste" }
    end

    trait :producer do
      profile_type { "producer" }
      name { "Produtor Teste" }
    end
  end
end
