require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert companies(:one).valid?
  end

  test "requires name and cnpj" do
    company = Company.new
    assert_not company.valid?
    assert_includes company.errors[:name], "não pode ficar em branco"
    assert_includes company.errors[:cnpj], "não pode ficar em branco"
  end

  test "requires a unique cnpj" do
    _owner, existing_company = create_company_with_owner!
    other_owner = User.create!(name: "Outro Dono", username: "dono_#{SecureRandom.hex(4)}", password: "senhasegura123", role: :owner)

    company = Company.new(name: "Duplicada", cnpj: existing_company.cnpj, owner: other_owner, address: create_college!.address)
    assert_not company.valid?
    assert_includes company.errors[:cnpj], "já está em uso"
  end

  test "builds and saves a nested address" do
    owner = User.create!(name: "Dono", username: "dono_#{SecureRandom.hex(4)}", password: "senhasegura123", role: :owner)

    company = Company.new(name: "Empresa Nova", cnpj: SecureRandom.hex(7), owner: owner)
    company.build_address(street: "Rua Nova", number: 10, neighborhood: "Centro", country: "Brasil", zip_code: "00000-000")

    assert company.save
    assert company.address.persisted?
  end
end
