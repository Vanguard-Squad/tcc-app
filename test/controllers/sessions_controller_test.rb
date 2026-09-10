require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "logs in with valid credentials and redirects to root when registration is complete" do
    owner, = create_company_with_owner!

    sign_in(owner)

    assert_redirected_to root_path
  end

  test "logs in but redirects to the company step when registration is incomplete" do
    owner = User.create!(name: "Sem Empresa", username: "semempresa_#{SecureRandom.hex(4)}", password: RegistrationTestHelpers::PASSWORD, role: :owner, is_active: true)

    sign_in(owner)

    assert_redirected_to new_registration_company_path
  end

  test "rejects an invalid password" do
    owner, = create_company_with_owner!

    post login_url, params: { username: owner.username, password: "senha_errada" }

    assert_response :unprocessable_entity
    assert_select ".flash-alert", text: "Usuário ou senha inválidos."
  end

  test "rejects a deactivated user" do
    owner, = create_company_with_owner!
    owner.update!(is_active: false)

    post login_url, params: { username: owner.username, password: RegistrationTestHelpers::PASSWORD }

    assert_response :unprocessable_entity
  end

  test "logs out and requires login again" do
    owner, = create_company_with_owner!
    sign_in(owner)

    delete logout_url
    assert_redirected_to login_path

    get root_url
    assert_redirected_to login_path
  end
end
