require "test_helper"

class CollegeTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert colleges(:one).valid?
  end

  test "requires a name" do
    college = College.new
    assert_not college.valid?
    assert_includes college.errors[:name], "não pode ficar em branco"
  end

  test "builds and saves a nested address" do
    college = College.new(name: "Faculdade Nova")
    college.build_address(street: "Rua da Faculdade", number: 1, neighborhood: "Bairro", country: "Brasil", zip_code: "00000-000")

    assert college.save
    assert college.address.persisted?
  end
end
