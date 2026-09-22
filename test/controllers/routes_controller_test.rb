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
end
