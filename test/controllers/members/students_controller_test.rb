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
            name: "Aluno", email: "aluno_#{SecureRandom.hex(4)}@example.com",
            password: "Senha@segura123", password_confirmation: "Senha@segura123",
            student_attributes: {
              cpf: SecureRandom.hex(6), birthdate: "2005-05-05", gender: "F", college_id: college.id,
              address_attributes: {
                street: "Rua do Aluno", number: 20, neighborhood: "Bairro", city: "Cidade Teste",
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

    test "owner creates a student together with a brand new college" do
      owner, = create_company_with_owner!
      sign_in(owner)

      assert_difference [ "User.count", "Student.count", "College.count" ], 1 do
        post member_students_url, params: {
          user: {
            name: "Aluno", email: "aluno_#{SecureRandom.hex(4)}@example.com",
            password: "Senha@segura123", password_confirmation: "Senha@segura123",
            student_attributes: {
              cpf: SecureRandom.hex(6), birthdate: "2005-05-05", gender: "F",
              address_attributes: {
                street: "Rua do Aluno", number: 20, neighborhood: "Bairro", city: "Cidade Teste",
                zip_code: "22222-000", country: "Brasil"
              },
              college_attributes: {
                name: "UNITRI",
                address_attributes: {
                  street: "Rua Nova Faculdade", number: 1, neighborhood: "Centro", city: "Patos de Minas",
                  zip_code: "38700-000", country: "Brasil"
                }
              }
            }
          }
        }
      end

      college = College.last
      assert_equal "UNITRI", college.name
      assert_equal "Patos de Minas", college.address.city
      assert_equal college, User.last.student.college
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
