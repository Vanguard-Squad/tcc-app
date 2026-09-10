require "test_helper"

module Members
  class StudentsControllerTest < ActionDispatch::IntegrationTest
    test "owner creates a student with a nested address, inheriting the owner's company" do
      owner, company = create_company_with_owner!
      college = create_college!
      sign_in(owner)

      assert_difference [ "User.count", "Student.count", "Address.count" ], 1 do
        post member_students_url, params: {
          user: {
            name: "Aluno", username: "aluno_#{SecureRandom.hex(4)}",
            password: "senhasegura123", password_confirmation: "senhasegura123",
            student_attributes: {
              cpf: SecureRandom.hex(6), birthdate: "2005-05-05", gender: "F", college_id: college.id,
              address_attributes: {
                street: "Rua do Aluno", number: 20, neighborhood: "Bairro",
                zip_code: "22222-000", country: "Brasil"
              }
            }
          }
        }
      end

      student_user = User.last
      assert student_user.student?
      assert_equal company, student_user.company
      assert_equal college, student_user.student.college
      assert_redirected_to members_path
    end

    test "manager can also create a student" do
      _owner, company = create_company_with_owner!
      manager = create_manager!(company: company)
      create_college!
      sign_in(manager)

      get new_member_student_url
      assert_response :success
    end
  end
end
