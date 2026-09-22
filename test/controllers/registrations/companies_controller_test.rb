require "test_helper"

module Registrations
  class CompaniesControllerTest < ActionDispatch::IntegrationTest
    test "requires authentication" do
      get new_registration_company_url
      assert_redirected_to login_path
    end

    test "creates the company and address, links it to the owner, and completes registration" do
      owner = User.create!(name: "Dona", email: "dona_#{SecureRandom.hex(4)}@example.com", password: RegistrationTestHelpers::PASSWORD, role: :owner, is_active: true)
      sign_in(owner)

      assert_difference [ "Company.count", "Address.count" ], 1 do
        post registration_companies_url, params: {
          company: {
            name: "Transportes Teste", cnpj: SecureRandom.hex(7),
            address_attributes: {
              street: "Av Central", number: 100, neighborhood: "Centro", city: "Cidade Teste",
              zip_code: "00000-000", country: "Brasil"
            }
          }
        }
      end

      assert_redirected_to root_path

      owner.reload
      assert owner.registration_complete?
      assert_equal owner.owned_company, owner.company
    end

    test "a user who already finished registration is redirected away" do
      owner, = create_company_with_owner!
      sign_in(owner)

      get new_registration_company_url
      assert_redirected_to root_path
    end
  end
end
