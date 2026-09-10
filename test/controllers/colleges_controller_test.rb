require "test_helper"

class CollegesControllerTest < ActionDispatch::IntegrationTest
  test "owner can list and create colleges" do
    owner, = create_company_with_owner!
    sign_in(owner)

    get colleges_url
    assert_response :success

    assert_difference [ "College.count", "Address.count" ], 1 do
      post colleges_url, params: {
        college: {
          name: "Faculdade Nova",
          address_attributes: {
            street: "Rua da Faculdade", number: 1, neighborhood: "Bairro",
            zip_code: "00000-000", country: "Brasil"
          }
        }
      }
    end

    assert_redirected_to colleges_path
  end

  test "driver cannot access colleges" do
    _owner, company = create_company_with_owner!
    driver = create_driver!(company: company)
    sign_in(driver)

    get colleges_url
    assert_redirected_to root_path
  end
end
