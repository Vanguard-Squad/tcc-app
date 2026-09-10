require "test_helper"

class MembersControllerTest < ActionDispatch::IntegrationTest
  test "owner sees everyone in their company" do
    owner, company = create_company_with_owner!
    manager = create_manager!(company: company)
    driver = create_driver!(company: company)
    sign_in(owner)

    get members_url
    assert_response :success
    assert_match owner.name, response.body
    assert_match manager.name, response.body
    assert_match driver.name, response.body
  end

  test "driver and student cannot access the members panel" do
    _owner, company = create_company_with_owner!
    driver = create_driver!(company: company)
    student = create_student!(company: company)

    sign_in(driver)
    get members_url
    assert_redirected_to root_path

    sign_in(student)
    get members_url
    assert_redirected_to root_path
  end
end
