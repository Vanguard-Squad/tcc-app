require "test_helper"

module Members
  class ManagersControllerTest < ActionDispatch::IntegrationTest
    test "owner creates a manager, who inherits the owner's company" do
      owner, company = create_company_with_owner!
      sign_in(owner)

      assert_difference "User.count", 1 do
        post member_managers_url, params: {
          user: {
            name: "Secretaria", username: "secretaria_#{SecureRandom.hex(4)}",
            password: "senhasegura123", password_confirmation: "senhasegura123"
          }
        }
      end

      manager = User.last
      assert manager.manager?
      assert_equal company, manager.company
      assert_redirected_to members_path
    end

    test "manager cannot create another manager" do
      _owner, company = create_company_with_owner!
      manager = create_manager!(company: company)
      sign_in(manager)

      assert_no_difference "User.count" do
        post member_managers_url, params: {
          user: {
            name: "Outra Secretaria", username: "outra_#{SecureRandom.hex(4)}",
            password: "senhasegura123", password_confirmation: "senhasegura123"
          }
        }
      end

      assert_redirected_to root_path
    end
  end
end
