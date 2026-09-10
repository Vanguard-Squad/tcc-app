require "test_helper"

class StudentTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert students(:one).valid?
  end

  test "requires a unique cpf" do
    _owner, company = create_company_with_owner!
    student_user = create_student!(company: company)
    another_user = User.create!(name: "Outro", username: "outro_#{SecureRandom.hex(4)}", password: "senhasegura123", role: :student, company: company)

    duplicate = Student.new(
      user: another_user, address: student_user.student.address, college: student_user.student.college,
      cpf: student_user.student.cpf, birthdate: 18.years.ago.to_date, gender: "M"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:cpf], "já está em uso"
  end

  test "builds and saves a nested address" do
    _owner, company = create_company_with_owner!
    college = create_college!
    user = User.new(name: "Aluno", username: "aluno_#{SecureRandom.hex(4)}", password: "senhasegura123", role: :student, company: company)
    user.build_student(cpf: SecureRandom.hex(6), birthdate: 18.years.ago.to_date, gender: "F", college: college)
    user.student.build_address(street: "Rua X", number: 1, neighborhood: "Bairro", country: "Brasil", zip_code: "00000-000")

    assert user.save
    assert user.student.address.persisted?
  end
end
