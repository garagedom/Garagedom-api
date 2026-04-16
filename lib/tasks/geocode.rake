namespace :geocode do
  desc "Geocode all profiles missing latitude/longitude"
  task profiles: :environment do
    profiles = Profile.where(latitude: nil).or(Profile.where(longitude: nil))
    total = profiles.count
    puts "#{total} perfis sem coordenadas encontrados"

    profiles.find_each.with_index(1) do |profile, i|
      Geocoding::UpdateCoordinatesService.new(profile).call
      profile.reload
      status = profile.latitude.present? ? "✓ #{profile.latitude}, #{profile.longitude}" : "✗ não encontrado"
      puts "[#{i}/#{total}] #{profile.name} (#{profile.city}) — #{status}"
      sleep 1 # Nominatim rate limit: 1 req/s
    end

    puts "Concluído."
  end
end
