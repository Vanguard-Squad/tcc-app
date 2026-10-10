require "test_helper"

module Members
  class EditingTest < ActionDispatch::IntegrationTest
    setup do
      @owner, @company = create_company_with_owner!
      @manager = create_manager!(company: @company)
    end

    test "manager edits a student's data and address without changing the password" do
      student_user = create_student!(company: @company)
      student = student_user.student
      sign_in(@manager)

      get edit_member_student_url(student_user)
      assert_response :success

      patch member_student_url(student_user), params: {
        user: {
          name: "Nome Corrigido", email: student_user.email, password: "", password_confirmation: "",
          student_attributes: {
            id: student.id, cpf: student.cpf, birthdate: student.birthdate, gender: "M", college_id: student.college_id,
            address_attributes: { id: student.address.id, street: "Rua Nova", number: 99, neighborhood: "Bairro",
              city: "Cidade Teste", country: "Brasil", zip_code: "22222-000" }
          }
        }
      }

      assert_redirected_to members_path
      student_user.reload
      assert_equal "Nome Corrigido", student_user.name
      assert_equal "M", student_user.student.gender
      assert_equal "Rua Nova", student_user.student.address.street
      assert student_user.authenticate(PASSWORD), "a senha atual deve ser mantida"

      log = Log.find_by!(action: "member.updated", auditable: student_user)
      assert_equal @manager, log.user
      assert_equal "Nome Corrigido", log.details["name"].last
    end

    test "manager edits a driver and sets a new password" do
      driver_user = create_driver!(company: @company)
      sign_in(@manager)

      patch member_driver_url(driver_user), params: {
        user: {
          name: driver_user.name, email: driver_user.email, password: "Nova@Senha123", password_confirmation: "Nova@Senha123",
          driver_attributes: { id: driver_user.driver.id, birthdate: "1985-02-02", drive_license: "CNH-NOVA" }
        }
      }

      assert_redirected_to members_path
      driver_user.reload
      assert_equal "CNH-NOVA", driver_user.driver.drive_license
      assert driver_user.authenticate("Nova@Senha123")
    end

    test "invalid edits re-render the form" do
      driver_user = create_driver!(company: @company)
      sign_in(@manager)

      patch member_driver_url(driver_user), params: { user: { name: "", email: driver_user.email } }
      assert_response :unprocessable_entity
    end

    test "manager cannot edit other managers, but the owner can" do
      other_manager = create_manager!(company: @company)

      sign_in(@manager)
      get edit_member_manager_url(other_manager)
      assert_redirected_to root_path

      sign_in(@owner)
      patch member_manager_url(other_manager), params: { user: { name: "Secretaria Editada", email: other_manager.email } }
      assert_redirected_to members_path
      assert_equal "Secretaria Editada", other_manager.reload.name
    end

    test "members from another company cannot be edited" do
      _other_owner, other_company = create_company_with_owner!
      foreign = create_driver!(company: other_company)
      sign_in(@manager)

      get edit_member_driver_url(foreign)
      assert_response :not_found
    end

    test "deactivated members cannot log in and lose their current session" do
      driver_user = create_driver!(company: @company)
      driver_session = open_session
      driver_session.post login_url, params: { email: driver_user.email, password: PASSWORD }
      driver_session.get drivers_route_url
      driver_session.assert_response :success

      sign_in(@manager)
      patch toggle_active_member_url(driver_user)
      assert_not driver_user.reload.is_active?
      assert Log.exists?(action: "member.deactivated", auditable: driver_user)

      driver_session.get drivers_route_url
      driver_session.assert_redirected_to login_path

      driver_session.post login_url, params: { email: driver_user.email, password: PASSWORD }
      driver_session.assert_response :unprocessable_entity

      sign_in(@manager)
      patch toggle_active_member_url(driver_user)
      assert driver_user.reload.is_active?
    end

    test "manager cannot deactivate the owner or themselves" do
      sign_in(@manager)

      patch toggle_active_member_url(@owner)
      assert_response :not_found
      patch toggle_active_member_url(@manager)
      assert_response :not_found
      assert @owner.reload.is_active?
      assert @manager.reload.is_active?
    end

    test "members list shows edit links only for manageable members" do
      create_driver!(company: @company)
      sign_in(@manager)

      get members_url
      assert_select "a", text: "Editar", count: 1
    end
  end
end
