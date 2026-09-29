# Helpers e estado compartilhado entre os arquivos de seed.
module Seeds
  PASSWORD = "Senha@segura123"

  # Guarda os registros criados para que os arquivos seguintes os reutilizem.
  def self.data
    @data ||= {}
  end

  # `company` é obrigatório (mesmo endereço pode existir em empresas diferentes).
  # Só o endereço da própria empresa é criado com `nil` na primeira execução:
  # a empresa o assume ao ser criada.
  def self.address!(company:, street:, number:, neighborhood:, city:, zip_code:, lat: nil, lng: nil, complement: nil, country: "Brasil")
    address = Address.find_or_initialize_by(company: company, street: street, number: number, zip_code: zip_code)
    address.assign_attributes(neighborhood: neighborhood, city: city, country: country, complement: complement)
    address.save!
    address.update_columns(latitude: lat, longitude: lng)
    address
  end

  def self.user!(email:, name:, role:, company: nil)
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(name: name, role: role, company: company, is_active: true)
    user.password = PASSWORD if user.new_record?
    user.save!
    user
  end

  def self.driver!(email:, name:, company:, cnpj_license:, birthdate:)
    user = user!(email: email, name: name, role: :driver, company: company)
    Driver.find_or_initialize_by(user: user).tap do |driver|
      driver.assign_attributes(drive_license: cnpj_license, birthdate: birthdate)
      driver.save!
    end
  end

  def self.student!(email:, name:, company:, college:, address:, cpf:, birthdate:, gender:)
    user = user!(email: email, name: name, role: :student, company: company)
    Student.find_or_initialize_by(user: user).tap do |student|
      student.assign_attributes(cpf: cpf, birthdate: birthdate, gender: gender, college: college, address: address)
      student.save!
    end
  end

  # A empresa da faculdade vem do endereço dela.
  def self.college!(name:, address:)
    college = College.joins(:address).find_by(name: name, addresses: { company_id: address.company_id }) || College.new(name: name)
    college.assign_attributes(address: address, is_active: true)
    college.save!
    college
  end

  def self.vehicle!(company:, plate:, seats:, route: nil, active: true)
    Vehicle.find_or_initialize_by(license_plate: plate).tap do |vehicle|
      vehicle.assign_attributes(company: company, seats: seats, route: route, is_active: active)
      vehicle.save!
    end
  end

  # Cria (ou atualiza) uma rota com as paradas na ordem informada.
  def self.route!(company:, name:, stops:)
    route = Route.find_or_create_by!(company: company, name: name)
    stops.each_with_index do |address, index|
      Stop.find_or_initialize_by(route: route, step: index + 1).tap do |stop|
        stop.address = address
        stop.save!
      end
    end
    route.stops.where("step > ?", stops.size).destroy_all
    route
  end

  def self.link_driver!(driver, vehicle, week_days)
    week_days.each { |day| VehicleDriver.find_or_create_by!(driver: driver, vehicle: vehicle, week_day: day) }
  end

  def self.link_student!(student, vehicle, outbound: true, return_trip: false)
    VehicleStudent.find_or_create_by!(student: student, vehicle: vehicle, is_return: false) if outbound
    VehicleStudent.find_or_create_by!(student: student, vehicle: vehicle, is_return: true) if return_trip
  end
end

# Sem rede: as coordenadas vêm dos próprios seeds (aproximadas, para demonstração).
Geocoder.configure(lookup: :test)
Geocoder::Lookup::Test.set_default_stub([])

WORKDAYS = %w[segunda terca quarta quinta sexta].freeze
