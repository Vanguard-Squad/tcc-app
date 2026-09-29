# Rotas, paradas e frota. Cobre: rota com ônibus, rota sem ônibus, ônibus sem
# rota e ônibus inativo.
#
# Coordenadas aproximadas (o mapa "gruda" nas ruas via OSRM).
company_a = Seeds.data.fetch(:company_a)
company_b = Seeds.data.fetch(:company_b)

def stop_address(company, street, number, neighborhood, city, zip, lat, lng)
  Seeds.address!(company: company, street: street, number: number, neighborhood: neighborhood, city: city, zip_code: zip, lat: lat, lng: lng)
end

# --- Empresa A ---
route_jardins = Seeds.route!(company: company_a, name: "Rota Jardins - UNITRI", stops: [
  stop_address(company_a, "Rua Augusta", 2690, "Jardim Paulista", "São Paulo", "01412-100", -23.5643738, -46.6668595),
  stop_address(company_a, "Rua Oscar Freire", 379, "Jardins", "São Paulo", "01426-001", -23.5665691, -46.6656264),
  stop_address(company_a, "Alameda Lorena", 1000, "Jardim Paulista", "São Paulo", "01424-001", -23.5675, -46.6620),
  stop_address(company_a, "Avenida Paulista", 1578, "Cerqueira César", "São Paulo", "01310-200", -23.5614, -46.6559)
])

route_consolacao = Seeds.route!(company: company_a, name: "Rota Consolação - Horizonte", stops: [
  stop_address(company_a, "Rua da Consolação", 2500, "Consolação", "São Paulo", "01302-000", -23.5484232, -46.6508633),
  stop_address(company_a, "Rua Haddock Lobo", 595, "Cerqueira César", "São Paulo", "01414-001", -23.5590, -46.6605),
  stop_address(company_a, "Avenida Brigadeiro Luís Antônio", 1500, "Bela Vista", "São Paulo", "01317-001", -23.5686, -46.6488)
])

route_sul = Seeds.route!(company: company_a, name: "Rota Zona Sul (sem ônibus)", stops: [
  stop_address(company_a, "Avenida Ibirapuera", 2000, "Moema", "São Paulo", "04029-200", -23.6090, -46.6650),
  stop_address(company_a, "Rua Pedro de Toledo", 500, "Vila Clementino", "São Paulo", "04039-001", -23.5980, -46.6470)
])

Seeds.data.merge!(
  route_jardins: route_jardins, route_consolacao: route_consolacao, route_sul: route_sul,
  vehicle_1: Seeds.vehicle!(company: company_a, plate: "ABC1D23", seats: 20, route: route_jardins),
  vehicle_2: Seeds.vehicle!(company: company_a, plate: "DEF4G56", seats: 15, route: route_consolacao),
  vehicle_reserve: Seeds.vehicle!(company: company_a, plate: "GHI7J89", seats: 30),
  vehicle_inactive: Seeds.vehicle!(company: company_a, plate: "JKL0M12", seats: 25, active: false)
)

# --- Empresa B ---
route_cambui = Seeds.route!(company: company_b, name: "Rota Cambuí - Campinas Tech", stops: [
  stop_address(company_b, "Avenida Francisco Glicério", 1100, "Centro", "Campinas", "13012-100", -22.9008, -47.0589),
  stop_address(company_b, "Rua Barão de Jaguara", 700, "Centro", "Campinas", "13015-001", -22.9040, -47.0606),
  stop_address(company_b, "Avenida Júlio de Mesquita", 500, "Cambuí", "Campinas", "13025-000", -22.8988, -47.0555)
])
Seeds.data.merge!(
  route_cambui: route_cambui,
  vehicle_b: Seeds.vehicle!(company: company_b, plate: "BBB1B11", seats: 18, route: route_cambui)
)
