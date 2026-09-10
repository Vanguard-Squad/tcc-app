require "test_helper"

class DriverTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert drivers(:one).valid?
  end

  test "requires a unique drive_license" do
    _owner, company = create_company_with_owner!
    driver_user = create_driver!(company: company)
    another_user = User.create!(name: "Outro", username: "outro_#{SecureRandom.hex(4)}", password: "senhasegura123", role: :driver, company: company)

    duplicate = Driver.new(user: another_user, birthdate: 30.years.ago.to_date, drive_license: driver_user.driver.drive_license)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:drive_license], "já está em uso"
  end
end
