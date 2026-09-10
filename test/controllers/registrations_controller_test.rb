require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "creates the account, signs in and moves to the company step" do
    assert_difference "User.count", 1 do
      post registrations_url, params: {
        user: {
          name: "Nova Dona", username: "nova_dona_#{SecureRandom.hex(4)}",
          password: "senhasegura123", password_confirmation: "senhasegura123"
        }
      }
    end

    assert_redirected_to new_registration_company_path

    user = User.last
    assert user.owner?
    assert user.is_active?
    assert_not user.registration_complete?
  end

  test "rejects a mismatched password confirmation" do
    assert_no_difference "User.count" do
      post registrations_url, params: {
        user: {
          name: "Falha", username: "falha_#{SecureRandom.hex(4)}",
          password: "senhasegura123", password_confirmation: "outra_senha"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "an already signed in user with incomplete registration is redirected to the company step" do
    owner = User.create!(name: "Meio Cadastro", username: "meio_#{SecureRandom.hex(4)}", password: RegistrationTestHelpers::PASSWORD, role: :owner, is_active: true)
    sign_in(owner)

    get new_registration_url
    assert_redirected_to new_registration_company_path
  end

  test "an already signed in user with complete registration is redirected to root" do
    owner, = create_company_with_owner!
    sign_in(owner)

    get new_registration_url
    assert_redirected_to root_path
  end
end
