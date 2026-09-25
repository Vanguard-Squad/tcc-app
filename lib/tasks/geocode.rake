namespace :addresses do
  desc "Geocode all addresses missing latitude/longitude"
  task geocode: :environment do
    Address.where(latitude: nil).or(Address.where(longitude: nil)).find_each do |address|
      address.geocode

      if address.save
        puts "Geocoded ##{address.id}: #{address.label_with_city} -> #{address.latitude}, #{address.longitude}"
      else
        puts "Failed to geocode ##{address.id}: #{address.errors.full_messages.join(', ')}"
      end

      sleep 1 # respeita o limite de 1 req/s do Nominatim
    end
  end
end
