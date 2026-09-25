require "test_helper"

class StudentTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert students(:one).valid?
  end

  test "requires a unique cpf" do
    _owner, company = create_company_with_owner!
    student_user = create_student!(company: company)
    another_user = User.create!(name: "Outro", email: "outro_#{SecureRandom.hex(4)}@example.com", password: "Senha@segura123", role: :student, company: company)

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
    user = User.new(name: "Aluno", email: "aluno_#{SecureRandom.hex(4)}@example.com", password: "Senha@segura123", role: :student, company: company)
    user.build_student(cpf: SecureRandom.hex(6), birthdate: 18.years.ago.to_date, gender: "F", college: college)
    user.student.build_address(street: "Rua X", number: 1, neighborhood: "Bairro", city: "Cidade Teste", country: "Brasil", zip_code: "00000-000")

    assert user.save
    assert user.student.address.persisted?
  end

  test "nearest_stop_for returns nil when the student's address is not geocoded" do
    _owner, company = create_company_with_owner!
    student_user = create_student!(company: company)
    route = create_route!(company: company)
    stop = create_stop!(route: route)
    stop.address.update!(latitude: -19.75, longitude: -47.93)

    assert_nil student_user.student.nearest_stop_for(route)
  end

  test "nearest_stop_for returns nil when no stop on the route is geocoded" do
    _owner, company = create_company_with_owner!
    student_user = create_student!(company: company)
    student_user.student.address.update!(latitude: -19.75, longitude: -47.93)
    route = create_route!(company: company)
    create_stop!(route: route)

    assert_nil student_user.student.nearest_stop_for(route)
  end

  test "nearest_stop_for picks the geographically closest stop" do
    _owner, company = create_company_with_owner!
    student_user = create_student!(company: company)
    student_user.student.address.update!(latitude: -19.7500, longitude: -47.9300)

    route = create_route!(company: company)
    near_stop = create_stop!(route: route, step: 1)
    near_stop.address.update!(latitude: -19.7510, longitude: -47.9310)

    mid_stop = create_stop!(route: route, step: 2)
    mid_stop.address.update!(latitude: -19.8000, longitude: -47.9800)

    far_stop = create_stop!(route: route, step: 3)
    far_stop.address.update!(latitude: -20.5000, longitude: -48.5000)

    assert_equal near_stop, student_user.student.nearest_stop_for(route)
  end
end
