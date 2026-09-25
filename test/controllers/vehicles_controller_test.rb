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

  test "owner links a route to a vehicle on create and can change it later" do
    owner, company = create_company_with_owner!
    route_a = create_route!(company: company)
    route_b = create_route!(company: company)
    sign_in(owner)

    post vehicles_url, params: { vehicle: { license_plate: "XYZ-9999", seats: 20, route_id: route_a.id } }
    vehicle = Vehicle.last
    assert_equal route_a, vehicle.route

    get edit_vehicle_url(vehicle)
    assert_response :success

    patch vehicle_url(vehicle), params: { vehicle: { route_id: route_b.id } }
    assert_redirected_to vehicles_path
    assert_equal route_b, vehicle.reload.route

    patch vehicle_url(vehicle), params: { vehicle: { route_id: "" } }
    assert_nil vehicle.reload.route
  end

  test "manager can link a route to a vehicle" do
    _owner, company = create_company_with_owner!
    manager = create_manager!(company: company)
    vehicle = create_vehicle!(company: company)
    route = create_route!(company: company)
    sign_in(manager)

    patch vehicle_url(vehicle), params: { vehicle: { route_id: route.id } }
    assert_equal route, vehicle.reload.route
  end

  test "cannot link a route from another company or edit another company's vehicle" do
    owner, company = create_company_with_owner!
    _other_owner, other_company = create_company_with_owner!
    vehicle = create_vehicle!(company: company)
    foreign_route = create_route!(company: other_company)
    foreign_vehicle = create_vehicle!(company: other_company)
    sign_in(owner)

    patch vehicle_url(vehicle), params: { vehicle: { route_id: foreign_route.id } }
    assert_response :unprocessable_entity
    assert_nil vehicle.reload.route

    get edit_vehicle_url(foreign_vehicle)
    assert_response :not_found
  end
end
