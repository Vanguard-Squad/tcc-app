require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert users(:one).valid?
  end

  test "requires name" do
    user = User.new(username: "sem_nome", password: "senhasegura123", role: :owner)
    assert_not user.valid?
    assert_includes user.errors[:name], "não pode ficar em branco"
  end

  test "requires a unique username, case-insensitively" do
    owner, = create_company_with_owner!
    user = User.new(name: "Outro", username: owner.username.upcase, password: "senhasegura123", role: :owner)

    assert_not user.valid?
    assert_includes user.errors[:username], "já está em uso"
  end

  test "rejects passwords shorter than 8 characters" do
    user = User.new(name: "Curto", username: "curto_#{SecureRandom.hex(4)}", password: "1234567", role: :owner)

    assert_not user.valid?
    assert_includes user.errors[:password], "é muito curto (mínimo: 8 caracteres)"
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

    lone = User.new(name: "Sem empresa", username: "solo_#{SecureRandom.hex(4)}", password: "senhasegura123", role: :owner)
    assert_not lone.registration_complete?
  end
end
