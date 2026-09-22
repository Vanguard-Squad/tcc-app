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
    college.build_address(street: "Rua da Faculdade", number: 1, neighborhood: "Bairro", city: "Cidade Teste", country: "Brasil", zip_code: "00000-000")

    assert college.save
    assert college.address.persisted?
  end

  test "label_with_city combines name and city, allowing the same name in different cities" do
    uberlandia = create_college!(name: "UNITRI", city: "Uberlândia")
    patos = create_college!(name: "UNITRI", city: "Patos de Minas")

    assert_equal "UNITRI - Uberlândia", uberlandia.label_with_city
    assert_equal "UNITRI - Patos de Minas", patos.label_with_city
    assert_not_equal uberlandia, patos
  end

  test "rejects a college whose address shares a zip_code with another college" do
    existing = create_college!
    duplicate = College.new(name: "Outra Faculdade")
    duplicate.build_address(
      street: "Rua X", number: 1, neighborhood: "Bairro", city: "Outra Cidade",
      country: "Brasil", zip_code: existing.address.zip_code
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "já existe uma faculdade cadastrada com esse CEP"
  end

  test "allows updating a college without tripping its own zip_code" do
    college = create_college!
    college.name = "Nome Atualizado"

    assert college.valid?
  end
end
