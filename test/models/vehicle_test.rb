require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert vehicles(:one).valid?
  end

  test "starts without a route and with no seats occupied" do
    _owner, company = create_company_with_owner!
    vehicle = create_vehicle!(company: company)

    assert_nil vehicle.route
    assert vehicle.is_active?
    assert_equal 0, vehicle.seats_busy
  end

  test "requires a unique license_plate" do
    _owner, company = create_company_with_owner!
    vehicle = create_vehicle!(company: company)

    duplicate = Vehicle.new(company: company, license_plate: vehicle.license_plate, seats: 10)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:license_plate], "já está em uso"
  end

  test "requires a positive integer number of seats" do
    _owner, company = create_company_with_owner!

    vehicle = Vehicle.new(company: company, license_plate: "XYZ-0001", seats: 0)
    assert_not vehicle.valid?
    assert_includes vehicle.errors[:seats], "precisa ser maior que 0"
  end
end
