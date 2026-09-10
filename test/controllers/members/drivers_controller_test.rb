require "test_helper"

module Members
  class DriversControllerTest < ActionDispatch::IntegrationTest
    test "manager creates a driver, who inherits the manager's company" do
      _owner, company = create_company_with_owner!
      manager = create_manager!(company: company)
      sign_in(manager)

      assert_difference [ "User.count", "Driver.count" ], 1 do
        post member_drivers_url, params: {
          user: {
            name: "Motorista", username: "motorista_#{SecureRandom.hex(4)}",
            password: "senhasegura123", password_confirmation: "senhasegura123",
            driver_attributes: { birthdate: "1990-01-01", drive_license: "CNH-#{SecureRandom.hex(5)}" }
          }
        }
      end

      driver = User.last
      assert driver.driver?
      assert_equal company, driver.company
      assert_equal company, driver.driver.reload.user.company
      assert_redirected_to members_path
    end

    test "driver cannot create another driver" do
      _owner, company = create_company_with_owner!
      driver = create_driver!(company: company)
      sign_in(driver)

      get new_member_driver_url
      assert_redirected_to root_path
    end
  end
end
