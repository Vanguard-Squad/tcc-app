ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module RegistrationTestHelpers
  PASSWORD = "senhasegura123"

  def create_company_with_owner!(name: "Empresa #{SecureRandom.hex(4)}")
    address = Address.create!(
      street: "Rua Teste", number: 1, neighborhood: "Centro",
      country: "Brasil", zip_code: "00000-000"
    )
    owner = User.create!(
      name: "Owner #{SecureRandom.hex(2)}", username: "owner_#{SecureRandom.hex(4)}",
      password: PASSWORD, role: :owner, is_active: true
    )
    company = Company.create!(name: name, cnpj: SecureRandom.hex(7), owner: owner, address: address)
    owner.update!(company: company)
    [ owner, company ]
  end

  def create_manager!(company:)
    User.create!(
      name: "Manager #{SecureRandom.hex(2)}", username: "manager_#{SecureRandom.hex(4)}",
      password: PASSWORD, role: :manager, is_active: true, company: company
    )
  end

  def create_driver!(company:)
    user = User.new(
      name: "Driver #{SecureRandom.hex(2)}", username: "driver_#{SecureRandom.hex(4)}",
      password: PASSWORD, role: :driver, is_active: true, company: company
    )
    user.build_driver(birthdate: 30.years.ago.to_date, drive_license: "CNH-#{SecureRandom.hex(5)}")
    user.save!
    user
  end

  def create_college!
    address = Address.create!(
      street: "Rua Faculdade", number: 1, neighborhood: "Bairro Universitário",
      country: "Brasil", zip_code: "11111-000"
    )
    College.create!(name: "Faculdade #{SecureRandom.hex(3)}", address: address, is_active: true)
  end

  def create_student!(company:, college: create_college!)
    address = Address.create!(
      street: "Rua Aluno", number: 1, neighborhood: "Bairro",
      country: "Brasil", zip_code: "22222-000"
    )
    user = User.new(
      name: "Student #{SecureRandom.hex(2)}", username: "student_#{SecureRandom.hex(4)}",
      password: PASSWORD, role: :student, is_active: true, company: company
    )
    user.build_student(cpf: SecureRandom.hex(6), birthdate: 18.years.ago.to_date, gender: "F", college: college, address: address)
    user.save!
    user
  end
end

module ActiveSupport
  class TestCase
    include RegistrationTestHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    def sign_in(user, password: RegistrationTestHelpers::PASSWORD)
      post login_url, params: { username: user.username, password: password }
    end
  end
end
