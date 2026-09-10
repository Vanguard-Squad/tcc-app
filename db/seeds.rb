# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

SEED_PASSWORD = "senhasegura123"

company_address = Address.find_or_create_by!(street: "Av. Paulista", number: 1000) do |address|
  address.neighborhood = "Bela Vista"
  address.country = "Brasil"
  address.zip_code = "01310-100"
end

owner = User.find_or_create_by!(username: "dona_empresa") do |user|
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

manager = User.find_or_create_by!(username: "secretaria") do |user|
  user.name = "Secretaria da Empresa"
  user.password = SEED_PASSWORD
  user.role = :manager
  user.is_active = true
  user.company = company
end

college_address = Address.find_or_create_by!(street: "Rua da Universidade", number: 500) do |address|
  address.neighborhood = "Cidade Universitária"
  address.country = "Brasil"
  address.zip_code = "05508-900"
end

college = College.find_or_create_by!(name: "Universidade Exemplo") do |c|
  c.address = college_address
  c.is_active = true
end

driver_user = User.find_or_create_by!(username: "motorista") do |user|
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

student_address = Address.find_or_create_by!(street: "Rua dos Alunos", number: 45) do |address|
  address.neighborhood = "Centro"
  address.country = "Brasil"
  address.zip_code = "01000-000"
end

student_user = User.find_or_create_by!(username: "aluno") do |user|
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

puts <<~SEEDS
  Seeds criados. Login (senha "#{SEED_PASSWORD}" para todos):
    dona_empresa  (owner)
    secretaria    (manager)
    motorista     (driver)
    aluno         (student)
SEEDS
