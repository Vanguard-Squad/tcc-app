require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  test "owner lists and creates vehicles without a route" do
    owner, = create_company_with_owner!
    sign_in(owner)

    get vehicles_url
    assert_response :success

    assert_difference "Vehicle.count", 1 do
      post vehicles_url, params: { vehicle: { license_plate: "ABC-1234", seats: 24 } }
    end

    vehicle = Vehicle.last
    assert_redirected_to vehicles_path
    assert_nil vehicle.route
    assert vehicle.is_active?
    assert_equal 0, vehicle.seats_busy
  end

  test "manager can also create a vehicle" do
    _owner, company = create_company_with_owner!
    manager = create_manager!(company: company)
    sign_in(manager)

    get new_vehicle_url
    assert_response :success
  end

  test "driver and student cannot access the fleet" do
    _owner, company = create_company_with_owner!
    driver = create_driver!(company: company)
    student = create_student!(company: company)

    sign_in(driver)
    get vehicles_url
    assert_redirected_to root_path

    sign_in(student)
    get vehicles_url
    assert_redirected_to root_path
  end
end
