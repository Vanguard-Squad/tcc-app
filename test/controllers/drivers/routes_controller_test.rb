require "test_helper"

module Drivers
  class RoutesControllerTest < ActionDispatch::IntegrationTest
    test "driver sees their assigned route and stops in order" do
      _owner, company = create_company_with_owner!
      driver_user = create_driver!(company: company)
      vehicle = create_vehicle!(company: company)
      route = create_route!(company: company)

      address_a = Address.create!(street: "Rua Alfa", number: 1, neighborhood: "Bairro", city: "Cidade Teste", country: "Brasil", zip_code: "10000-000")
      address_b = Address.create!(street: "Rua Beta", number: 2, neighborhood: "Bairro", city: "Cidade Teste", country: "Brasil", zip_code: "20000-000")
      stop_b = route.stops.create!(address: address_b, step: 2)
      stop_a = route.stops.create!(address: address_a, step: 1)
      vehicle.update!(route: route)
      create_vehicle_driver!(driver: driver_user.driver, vehicle: vehicle)

      sign_in(driver_user)
      get drivers_route_url

      assert_response :success
      body = response.body
      assert_operator body.index(stop_a.address.label_with_city), :<, body.index(stop_b.address.label_with_city)
    end

    test "driver with no vehicle assigned sees empty state instead of crashing" do
      _owner, company = create_company_with_owner!
      driver_user = create_driver!(company: company)
      sign_in(driver_user)

      get drivers_route_url
      assert_response :success

      get passengers_drivers_route_url
      assert_response :success

      get edit_drivers_route_url
      assert_redirected_to drivers_route_path
    end

    test "owner, manager and student cannot access driver routes" do
      _owner, company = create_company_with_owner!
      owner = _owner
      manager = create_manager!(company: company)
      student_user = create_student!(company: company)

      [ owner, manager, student_user ].each do |user|
        sign_in(user)
        get drivers_route_url
        assert_redirected_to root_path
      end
    end

    test "driver only sees their own route, not another driver's" do
      _owner, company = create_company_with_owner!

      driver_a = create_driver!(company: company)
      vehicle_a = create_vehicle!(company: company)
      route_a = create_route!(company: company, name: "Rota A")
      stop_a = create_stop!(route: route_a, step: 1)
      vehicle_a.update!(route: route_a)
      create_vehicle_driver!(driver: driver_a.driver, vehicle: vehicle_a)

      driver_b = create_driver!(company: company)
      vehicle_b = create_vehicle!(company: company)
      route_b = create_route!(company: company, name: "Rota B")
      create_stop!(route: route_b, step: 1)
      vehicle_b.update!(route: route_b)
      create_vehicle_driver!(driver: driver_b.driver, vehicle: vehicle_b)

      sign_in(driver_a)
      get drivers_route_url

      assert_response :success
      assert_match route_a.name, response.body
      assert_match stop_a.address.label_with_city, response.body
      assert_no_match(/#{Regexp.escape(route_b.name)}/, response.body)
    end

    test "update reorders stops according to submitted stop_ids" do
      _owner, company = create_company_with_owner!
      driver_user = create_driver!(company: company)
      vehicle = create_vehicle!(company: company)
      route = create_route!(company: company)
      stop_1 = create_stop!(route: route, step: 1)
      stop_2 = create_stop!(route: route, step: 2)
      vehicle.update!(route: route)
      create_vehicle_driver!(driver: driver_user.driver, vehicle: vehicle)

      sign_in(driver_user)
      patch drivers_route_url, params: { stop_ids: [ stop_2.id, stop_1.id ] }

      assert_redirected_to drivers_route_path
      assert_equal 1, stop_2.reload.step
      assert_equal 2, stop_1.reload.step
    end

    test "update ignores a submission with a foreign stop id" do
      _owner, company = create_company_with_owner!
      driver_user = create_driver!(company: company)
      vehicle = create_vehicle!(company: company)
      route = create_route!(company: company)
      stop_1 = create_stop!(route: route, step: 1)
      vehicle.update!(route: route)
      create_vehicle_driver!(driver: driver_user.driver, vehicle: vehicle)

      other_stop = create_stop!(route: create_route!(company: company), step: 1)

      sign_in(driver_user)
      patch drivers_route_url, params: { stop_ids: [ other_stop.id ] }

      assert_redirected_to edit_drivers_route_path
      assert_equal 1, stop_1.reload.step
    end

    test "passengers are grouped by nearest stop and split by direction" do
      _owner, company = create_company_with_owner!
      driver_user = create_driver!(company: company)
      vehicle = create_vehicle!(company: company)
      route = create_route!(company: company)

      near_stop = create_stop!(route: route, step: 1)
      near_stop.address.update!(latitude: -19.7500, longitude: -47.9300)

      far_stop = create_stop!(route: route, step: 2)
      far_stop.address.update!(latitude: -20.5000, longitude: -48.5000)

      vehicle.update!(route: route)
      create_vehicle_driver!(driver: driver_user.driver, vehicle: vehicle)

      student_user = create_student!(company: company)
      student_user.student.address.update!(latitude: -19.7510, longitude: -47.9310)
      create_vehicle_student!(vehicle: vehicle, student: student_user.student, is_return: false)

      sign_in(driver_user)
      get passengers_drivers_route_url

      assert_response :success
      outbound_section, return_section = response.body.split("Volta (embarque na faculdade, desembarque na parada)", 2)

      assert_includes outbound_section, student_user.name
      assert_includes outbound_section, near_stop.address.label_with_city
      assert_not_includes return_section, student_user.name
    end
  end
end
