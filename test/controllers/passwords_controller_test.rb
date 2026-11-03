require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  NEW_PASSWORD = "Minha@nova123"

  setup do
    @owner, @company = create_company_with_owner!
    @student_user = create_student!(company: @company, contract: nil)
    @student_user.update!(must_change_password: true)
  end

  test "student registered by the office must change the password on first login" do
    sign_in(@owner)
    post member_students_url, params: { user: {
      name: "Novo Aluno", email: "novo_aluno@example.com",
      password: RegistrationTestHelpers::PASSWORD, password_confirmation: RegistrationTestHelpers::PASSWORD,
      student_attributes: {
        cpf: "99988877766", birthdate: "2005-01-01", gender: "M", college_id: @student_user.student.college_id,
        address_attributes: { street: "Rua", number: 1, neighborhood: "Bairro", city: "Cidade", country: "Brasil", zip_code: "00000-000" }
      }
    } }
    assert User.find_by(email: "novo_aluno@example.com").must_change_password?
  end

  test "login sends the student to the password page before anything else" do
    sign_in(@student_user)
    assert_redirected_to edit_password_path

    get root_url
    assert_redirected_to edit_password_path
    get students_contract_url
    assert_redirected_to edit_password_path
  end

  test "changing the password releases the student to the contract step" do
    sign_in(@student_user)

    patch password_url, params: { current_password: RegistrationTestHelpers::PASSWORD, password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD }
    assert_redirected_to root_path
    assert_not @student_user.reload.must_change_password?
    assert @student_user.authenticate(NEW_PASSWORD)

    get root_url
    assert_redirected_to students_contract_path
  end

  test "wrong current password is rejected" do
    sign_in(@student_user)

    patch password_url, params: { current_password: "errada", password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD }
    assert_response :unprocessable_entity
    assert @student_user.reload.must_change_password?
  end

  test "the new password cannot repeat the temporary one or be blank" do
    sign_in(@student_user)

    patch password_url, params: { current_password: RegistrationTestHelpers::PASSWORD, password: RegistrationTestHelpers::PASSWORD, password_confirmation: RegistrationTestHelpers::PASSWORD }
    assert_response :unprocessable_entity

    patch password_url, params: { current_password: RegistrationTestHelpers::PASSWORD, password: "", password_confirmation: "" }
    assert_response :unprocessable_entity
    assert @student_user.reload.must_change_password?
  end

  test "weak or mismatched passwords are rejected" do
    sign_in(@student_user)

    patch password_url, params: { current_password: RegistrationTestHelpers::PASSWORD, password: "fraca", password_confirmation: "fraca" }
    assert_response :unprocessable_entity

    patch password_url, params: { current_password: RegistrationTestHelpers::PASSWORD, password: NEW_PASSWORD, password_confirmation: "Outra@senha1" }
    assert_response :unprocessable_entity
    assert @student_user.reload.must_change_password?
  end

  test "student can log out before changing the password" do
    sign_in(@student_user)

    delete logout_url
    assert_redirected_to login_path
  end

  test "office resetting a student password makes it temporary again" do
    @student_user.update!(must_change_password: false)
    sign_in(@owner)

    patch member_student_url(@student_user), params: { user: { password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD } }
    assert @student_user.reload.must_change_password?
  end
end
