# Alunos e vínculos com os ônibus. Cobre: ida e volta, só ida, só volta,
# endereço sem localização (cai em "sem parada definida"), aluno sem ônibus.
company_a = Seeds.data.fetch(:company_a)
company_b = Seeds.data.fetch(:company_b)
unitri = Seeds.data.fetch(:unitri_a)
horizonte = Seeds.data.fetch(:horizonte_a)
vehicle_1 = Seeds.data.fetch(:vehicle_1)
vehicle_2 = Seeds.data.fetch(:vehicle_2)

def home(street, number, neighborhood, zip, lat, lng)
  Seeds.address!(company: Seeds.data.fetch(:company_a), street: street, number: number, neighborhood: neighborhood, city: "São Paulo", zip_code: zip, lat: lat, lng: lng)
end

# --- Ônibus 1 (Rota Jardins - UNITRI) ---
ana = Seeds.student!(email: "aluno@transportes.com", name: "Ana Aluna", company: company_a, college: unitri, cpf: "98765432100",
                     birthdate: Date.new(2005, 4, 10), gender: "F",
                     address: home("Rua Haddock Lobo", 1200, "Cerqueira César", "01414-002", -23.5610, -46.6665))
bruno = Seeds.student!(email: "bruno@transportes.com", name: "Bruno Só Ida", company: company_a, college: unitri, cpf: "11122233301",
                       birthdate: Date.new(2004, 8, 22), gender: "M",
                       address: home("Rua Bela Cintra", 1800, "Consolação", "01415-001", -23.5675, -46.6650))
carla = Seeds.student!(email: "carla@transportes.com", name: "Carla Só Volta", company: company_a, college: unitri, cpf: "11122233302",
                       birthdate: Date.new(2003, 12, 5), gender: "F",
                       address: home("Alameda Lorena", 1200, "Jardim Paulista", "01424-002", -23.5690, -46.6625))
diego = Seeds.student!(email: "diego@transportes.com", name: "Diego Sem Localização", company: company_a, college: unitri, cpf: "11122233303",
                       birthdate: Date.new(2005, 2, 17), gender: "M",
                       address: home("Rua Sem Localização nos Mapas", 10, "Centro", "01000-000", nil, nil))

Seeds.link_student!(ana, vehicle_1, outbound: true, return_trip: true)
Seeds.link_student!(bruno, vehicle_1, outbound: true)
Seeds.link_student!(carla, vehicle_1, outbound: false, return_trip: true)
Seeds.link_student!(diego, vehicle_1, outbound: true, return_trip: true)

# --- Ônibus 2 (Rota Consolação - Horizonte) ---
fabio = Seeds.student!(email: "fabio@transportes.com", name: "Fábio Viagem Ativa", company: company_a, college: horizonte, cpf: "11122233304",
                       birthdate: Date.new(2004, 6, 30), gender: "M",
                       address: home("Rua Sergipe", 300, "Consolação", "01243-001", -23.5470, -46.6500))
gabi = Seeds.student!(email: "gabi@transportes.com", name: "Gabi Ida e Volta", company: company_a, college: horizonte, cpf: "11122233305",
                      birthdate: Date.new(2006, 1, 9), gender: "F",
                      address: home("Rua Peixoto Gomide", 1000, "Cerqueira César", "01409-001", -23.5590, -46.6560))
Seeds.link_student!(fabio, vehicle_2, outbound: true)
Seeds.link_student!(gabi, vehicle_2, outbound: true, return_trip: true)

# --- Aluno sem ônibus (tela mostra o estado vazio) ---
elisa = Seeds.student!(email: "elisa@transportes.com", name: "Elisa Sem Ônibus", company: company_a, college: horizonte, cpf: "11122233306",
                       birthdate: Date.new(2005, 9, 25), gender: "F",
                       address: home("Rua Frei Caneca", 800, "Consolação", "01307-001", -23.5530, -46.6520))

# --- Empresa B ---
henrique = Seeds.student!(email: "henrique@campinas.com", name: "Henrique Campinas", company: company_b, college: Seeds.data.fetch(:tech_b),
                          cpf: "33344455501", birthdate: Date.new(2004, 5, 12), gender: "M",
                          address: Seeds.address!(company: company_b, street: "Rua Barão de Jaguara", number: 900, neighborhood: "Centro", city: "Campinas",
                                                  zip_code: "13015-002", lat: -22.9045, lng: -47.0610))
Seeds.link_student!(henrique, Seeds.data.fetch(:vehicle_b), outbound: true, return_trip: true)

# Lotação atual de cada ônibus.
Vehicle.find_each { |vehicle| vehicle.update!(seats_busy: vehicle.vehicle_students.distinct.count(:student_id)) }

Seeds.data.merge!(ana: ana, bruno: bruno, carla: carla, diego: diego, fabio: fabio, gabi: gabi, elisa: elisa, henrique: henrique)
