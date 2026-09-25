# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

SEED_PASSWORD = "Senha@segura123"

company_address = Address.find_or_create_by!(street: "Av. Paulista", number: 1000) do |address|
  address.neighborhood = "Bela Vista"
  address.city = "São Paulo"
  address.country = "Brasil"
  address.zip_code = "01310-100"
end

owner = User.find_or_create_by!(email: "dona@transportes.com") do |user|
  user.name = "Maria Dona"
  user.password = SEED_PASSWORD
  user.role = :owner
  user.is_active = true
end

company = Company.find_or_create_by!(cnpj: "12345678000199") do |c|
  c.name = "Transportes Escolares Ltda"
  c.owner = owner
  c.address = company_address
end

owner.update!(company: company) if owner.company_id != company.id

manager = User.find_or_create_by!(email: "secretaria@transportes.com") do |user|
  user.name = "Secretaria da Empresa"
  user.password = SEED_PASSWORD
  user.role = :manager
  user.is_active = true
  user.company = company
end

college_address = Address.find_or_create_by!(street: "Rua da Universidade", number: 500) do |address|
  address.neighborhood = "Cidade Universitária"
  address.city = "Uberlândia"
  address.country = "Brasil"
  address.zip_code = "38400-100"
end

college = College.find_or_create_by!(name: "UNITRI", address: college_address) do |c|
  c.is_active = true
end

other_college_address = Address.find_or_create_by!(street: "Av. Getúlio Vargas", number: 100) do |address|
  address.neighborhood = "Centro"
  address.city = "Patos de Minas"
  address.country = "Brasil"
  address.zip_code = "38700-000"
end

College.find_or_create_by!(name: "UNITRI", address: other_college_address) do |c|
  c.is_active = true
end

driver_user = User.find_or_create_by!(email: "motorista@transportes.com") do |user|
  user.name = "José Motorista"
  user.password = SEED_PASSWORD
  user.role = :driver
  user.is_active = true
  user.company = company
end
Driver.find_or_create_by!(user: driver_user) do |driver|
  driver.birthdate = 35.years.ago.to_date
  driver.drive_license = "12345678900"
end

student_address = Address.find_or_create_by!(street: "Rua Augusta", number: 2690) do |address|
  address.neighborhood = "Jardim Paulista"
  address.city = "São Paulo"
  address.country = "Brasil"
  address.zip_code = "01412-100"
end

student_user = User.find_or_create_by!(email: "aluno@transportes.com") do |user|
  user.name = "Ana Aluna"
  user.password = SEED_PASSWORD
  user.role = :student
  user.is_active = true
  user.company = company
end
Student.find_or_create_by!(user: student_user) do |student|
  student.cpf = "98765432100"
  student.birthdate = 18.years.ago.to_date
  student.gender = "F"
  student.college = college
  student.address = student_address
end

driver = driver_user.driver
student = student_user.student

vehicle = Vehicle.find_or_create_by!(license_plate: "ABC1D23") do |v|
  v.company = company
  v.seats = 20
end

route = Route.find_or_create_by!(name: "Rota Centro - UNITRI", company: company)

second_stop_address = Address.find_or_create_by!(street: "Rua Oscar Freire", number: 379) do |address|
  address.neighborhood = "Jardins"
  address.city = "São Paulo"
  address.country = "Brasil"
  address.zip_code = "01426-001"
end

Stop.find_or_create_by!(route: route, address: student_address) { |stop| stop.step = 1 }
Stop.find_or_create_by!(route: route, address: second_stop_address) { |stop| stop.step = 2 }

vehicle.update!(route: route) if vehicle.route_id != route.id

VehicleDriver.find_or_create_by!(driver: driver, vehicle: vehicle) do |vd|
  vd.week_day = Driver::WEEK_DAYS[Date.current.wday]
end

VehicleStudent.find_or_create_by!(vehicle: vehicle, student: student, is_return: false)
VehicleStudent.find_or_create_by!(vehicle: vehicle, student: student, is_return: true)

puts <<~SEEDS
  Seeds criados. Login (senha "#{SEED_PASSWORD}" para todos):
    dona@transportes.com        (owner)
    secretaria@transportes.com  (manager)
    motorista@transportes.com   (driver)
    aluno@transportes.com       (student)
SEEDS
