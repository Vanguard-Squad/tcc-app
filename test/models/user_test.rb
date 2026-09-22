require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert users(:one).valid?
  end

  test "requires name" do
    user = User.new(email: "sem_nome@example.com", password: "Senha@segura123", role: :owner)
    assert_not user.valid?
    assert_includes user.errors[:name], "não pode ficar em branco"
  end

  test "requires a valid email format" do
    user = User.new(name: "Invalido", email: "nao-e-um-email", password: "Senha@segura123", role: :owner)

    assert_not user.valid?
    assert_includes user.errors[:email], "não é válido"
  end

  test "requires a unique email, case-insensitively" do
    owner, = create_company_with_owner!
    user = User.new(name: "Outro", email: owner.email.upcase, password: "Senha@segura123", role: :owner)

    assert_not user.valid?
    assert_includes user.errors[:email], "já está em uso"
  end

  test "requires at least 8 characters, an uppercase letter, a lowercase letter and a special character" do
    [
      "semmaiuscula1!",
      "SEMMINUSCULA1!",
      "SemEspecial123",
      "Curto1!"
    ].each do |password|
      user = User.new(name: "Teste", email: "senha_#{SecureRandom.hex(4)}@example.com", password: password, role: :owner)
      assert_not user.valid?, "#{password.inspect} deveria ser invalida"
    end

    valid_user = User.new(name: "Teste", email: "senha_valida_#{SecureRandom.hex(4)}@example.com", password: "Senha@segura123", role: :owner)
    assert valid_user.valid?
  end

  test "rejects a role outside the enum" do
    assert_raises(ArgumentError) { User.new(role: "admin") }
  end

  test "password is stored hashed and verified via authenticate" do
    owner, = create_company_with_owner!

    assert_not_equal RegistrationTestHelpers::PASSWORD, owner.password_digest
    assert owner.authenticate(RegistrationTestHelpers::PASSWORD)
    assert_not owner.authenticate("senha_errada")
  end

  test "registration_complete? is true once company_id is set" do
    owner, = create_company_with_owner!
    assert owner.registration_complete?

    lone = User.new(name: "Sem empresa", email: "solo_#{SecureRandom.hex(4)}@example.com", password: "Senha@segura123", role: :owner)
    assert_not lone.registration_complete?
  end
end
