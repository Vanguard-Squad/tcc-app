require "test_helper"

class RoutesControllerTest < ActionDispatch::IntegrationTest
  test "owner creates a route with a brand new stop address" do
    owner, = create_company_with_owner!
    sign_in(owner)

    assert_difference [ "Route.count", "Stop.count", "Address.count" ], 1 do
      post routes_url, params: {
        route: {
          name: "Rota Centro",
          stops_attributes: {
            "0" => {
              address_attributes: {
                street: "Rua da Parada", number: 10, neighborhood: "Bairro", city: "Cidade Teste",
                zip_code: "44444-000", country: "Brasil"
              }
            }
          }
        }
      }
    end

    route = Route.last
    assert_equal owner.company, route.company
    assert_equal [ 1 ], route.stops.pluck(:step)
    assert_redirected_to routes_path
  end

  test "owner reuses an existing stop address instead of duplicating it" do
    owner, company = create_company_with_owner!
    existing_route = create_route!(company: company)
    existing_stop = create_stop!(route: existing_route)
    sign_in(owner)

    assert_difference "Stop.count", 1 do
      assert_no_difference "Address.count" do
        post routes_url, params: {
          route: {
            name: "Rota Bairro",
            stops_attributes: { "0" => { address_id: existing_stop.address_id } }
          }
        }
      end
    end

    assert_equal existing_stop.address, Route.last.stops.first.address
  end

  test "stops are numbered in the order they are submitted" do
    owner, company = create_company_with_owner!
    address_a = create_stop!(route: create_route!(company: company)).address
    address_b = create_stop!(route: create_route!(company: company)).address
    sign_in(owner)

    post routes_url, params: {
      route: {
        name: "Rota Longa",
        stops_attributes: {
          "0" => { address_id: address_a.id },
          "1" => { address_id: address_b.id }
        }
      }
    }

    stops = Route.last.stops.order(:step)
    assert_equal [ address_a, address_b ], stops.map(&:address)
    assert_equal [ 1, 2 ], stops.pluck(:step)
  end

  test "manager can also create a route" do
    _owner, company = create_company_with_owner!
    manager = create_manager!(company: company)
    sign_in(manager)

    get new_route_url
    assert_response :success
  end

  test "driver and student cannot access routes" do
    _owner, company = create_company_with_owner!
    driver = create_driver!(company: company)
    student = create_student!(company: company)

    sign_in(driver)
    get routes_url
    assert_redirected_to root_path

    sign_in(student)
    get routes_url
    assert_redirected_to root_path
  end

  test "new route form renders the address fields for a stop" do
    owner, = create_company_with_owner!
    sign_in(owner)

    get new_route_url

    assert_response :success
    assert_select "fieldset input[name='route[stops_attributes][0][address_attributes][street]']"
    assert_select "fieldset input[name='route[stops_attributes][0][address_attributes][zip_code]']"
  end

  test "owner edits a route: renames, swaps a stop address, removes a stop and adds a new one" do
    owner, company = create_company_with_owner!
    route = create_route!(company: company)
    stop_a = create_stop!(route: route, step: 1)
    stop_b = create_stop!(route: route, step: 2)
    stop_c = create_stop!(route: route, step: 3)
    other_address = create_stop!(route: create_route!(company: company)).address
    sign_in(owner)

    get edit_route_url(route)
    assert_response :success
    assert_select "input[name='route[stops_attributes][0][_destroy]']"

    assert_difference "Stop.count", 0 do
      patch route_url(route), params: {
        route: {
          name: "Rota Editada",
          stops_attributes: {
            "0" => { id: stop_a.id, address_id: other_address.id },
            "1" => { id: stop_b.id, _destroy: "1", address_id: stop_b.address_id },
            "2" => { id: stop_c.id, _destroy: "0", address_id: stop_c.address_id },
            "3" => { address_attributes: {
              street: "Rua Nova", number: 7, neighborhood: "Bairro", city: "Cidade Teste",
              zip_code: "55555-000", country: "Brasil"
            } }
          }
        }
      }
    end

    assert_redirected_to routes_path
    route.reload
    assert_equal "Rota Editada", route.name
    stops = route.stops.order(:step)
    assert_equal [ 1, 2, 3 ], stops.pluck(:step)
    assert_equal [ other_address, stop_c.address, Address.find_by(street: "Rua Nova") ], stops.map(&:address)
    assert_not Stop.exists?(stop_b.id)
  end

  test "manager can edit a route" do
    _owner, company = create_company_with_owner!
    manager = create_manager!(company: company)
    route = create_route!(company: company)
    create_stop!(route: route)
    sign_in(manager)

    get edit_route_url(route)
    assert_response :success
  end

  test "cannot edit another company's route, and drivers cannot edit routes" do
    owner, company = create_company_with_owner!
    _other_owner, other_company = create_company_with_owner!
    foreign_route = create_route!(company: other_company)
    own_route = create_route!(company: company)
    driver = create_driver!(company: company)

    sign_in(owner)
    get edit_route_url(foreign_route)
    assert_response :not_found
    patch route_url(foreign_route), params: { route: { name: "Hack" } }
    assert_response :not_found

    sign_in(driver)
    get edit_route_url(own_route)
    assert_redirected_to root_path
  end
end
