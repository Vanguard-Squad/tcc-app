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
    _owner, company = create_company_with_owner!
    college = College.new(name: "Faculdade Nova")
    college.build_address(street: "Rua da Faculdade", number: 1, neighborhood: "Bairro", city: "Cidade Teste", country: "Brasil", zip_code: "00000-000", company: company)

    assert college.save
    assert college.address.persisted?
  end

  test "label_with_city combines name and city, allowing the same name in different cities" do
    _owner, company = create_company_with_owner!
    uberlandia = create_college!(company: company, name: "UNITRI", city: "Uberlândia")
    patos = create_college!(company: company, name: "UNITRI", city: "Patos de Minas")

    assert_equal "UNITRI - Uberlândia", uberlandia.label_with_city
    assert_equal "UNITRI - Patos de Minas", patos.label_with_city
    assert_not_equal uberlandia, patos
  end

  test "rejects a college whose address shares a zip_code with another college of the same company" do
    _owner, company = create_company_with_owner!
    existing = create_college!(company: company)
    duplicate = College.new(name: "Outra Faculdade")
    duplicate.build_address(
      street: "Rua X", number: 1, neighborhood: "Bairro", city: "Outra Cidade",
      country: "Brasil", zip_code: existing.address.zip_code, company: company
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "já existe uma faculdade da sua empresa cadastrada com esse CEP"
  end

  test "another company can register a college with the same zip_code" do
    _owner, company = create_company_with_owner!
    _other_owner, other_company = create_company_with_owner!
    existing = create_college!(company: company)
    other = College.new(name: existing.name)
    other.build_address(
      street: "Rua X", number: 1, neighborhood: "Bairro", city: existing.address.city,
      country: "Brasil", zip_code: existing.address.zip_code, company: other_company
    )

    assert other.valid?
  end

  test "the company comes from the address" do
    _owner, company = create_company_with_owner!

    assert_equal company, create_college!(company: company).company
  end

  test "requires an address that belongs to a company" do
    college = College.new(name: "Sem empresa")
    college.build_address(street: "Rua X", number: 1, neighborhood: "Bairro", city: "Cidade", country: "Brasil", zip_code: "00000-001")

    assert_not college.valid?
    assert_includes college.errors[:company], "precisa existir"
  end

  test "allows updating a college without tripping its own zip_code" do
    _owner, company = create_company_with_owner!
    college = create_college!(company: company)
    college.name = "Nome Atualizado"

    assert college.valid?
  end
end
