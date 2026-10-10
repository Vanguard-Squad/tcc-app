require "test_helper"

class AuditLogsControllerTest < ActionDispatch::IntegrationTest
  test "owner sees the company's audit trail, including logins" do
    owner, company = create_company_with_owner!
    manager = create_manager!(company: company)
    sign_in(manager)
    sign_in(owner)

    get audit_logs_url

    assert_response :success
    assert_select "td", text: "Entrou no sistema", minimum: 2
    assert_match manager.name, response.body
  end

  test "logs from other companies are not shown" do
    owner, = create_company_with_owner!
    other_owner, = create_company_with_owner!
    sign_in(other_owner)
    sign_in(owner)

    get audit_logs_url
    assert_no_match other_owner.name, response.body
  end

  test "filters by user and category" do
    owner, company = create_company_with_owner!
    manager = create_manager!(company: company)
    sign_in(manager)
    post member_drivers_url, params: {
      user: {
        name: "Motorista Novo", email: "novo_#{SecureRandom.hex(4)}@example.com",
        password: PASSWORD, password_confirmation: PASSWORD,
        driver_attributes: { birthdate: "1990-01-01", drive_license: "CNH-#{SecureRandom.hex(4)}" }
      }
    }
    sign_in(owner)

    get audit_logs_url, params: { user_id: manager.id, category: "member" }

    assert_select "tbody tr", count: 1
    assert_select "td", text: "Cadastrou membro"
  end

  test "managers, drivers and students cannot see the audit page" do
    _owner, company = create_company_with_owner!

    [ create_manager!(company: company), create_driver!(company: company), create_student!(company: company) ].each do |user|
      sign_in(user)
      get audit_logs_url
      assert_redirected_to root_path
    end
  end

  test "failed logins and logouts are recorded" do
    owner, = create_company_with_owner!

    assert_difference -> { Log.where(user: owner, action: "session.login_failed").count }, 1 do
      post login_url, params: { email: owner.email, password: "errada" }
    end

    sign_in(owner)
    assert_difference -> { Log.where(user: owner, action: "session.logout").count }, 1 do
      delete logout_url
    end
  end
end
