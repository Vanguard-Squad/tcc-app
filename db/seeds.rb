# Dados de desenvolvimento/demonstração, organizados por tema em db/seeds/*.rb
# (carregados em ordem alfabética). Idempotente: pode rodar `bin/rails db:seed`
# várias vezes. Não faz chamadas de rede: as coordenadas dos endereços são
# fixas (ver db/seeds/00_support.rb).
#
# Para começar do zero: bin/rails db:reset

original_geocoder_lookup = Geocoder.config.lookup

begin
  Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |file| load file }
ensure
  Geocoder.configure(lookup: original_geocoder_lookup)
end
