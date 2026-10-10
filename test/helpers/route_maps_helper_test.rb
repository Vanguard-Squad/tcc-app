require "test_helper"

class RouteMapsHelperTest < ActionView::TestCase
  test "stops follow the route order on the way out and the reverse order on the way back" do
    _owner, company = create_company_with_owner!
    route = create_route!(company: company)
    first = create_stop!(route: route, step: 1)
    second = create_stop!(route: route, step: 2)
    stops = route.stops.includes(:address).to_a

    assert_equal [ first.id, second.id ], route_stops_for_map(stops, direction: "outbound").pluck(:id)
    assert_equal [ second.id, first.id ], route_stops_for_map(stops, direction: "return").pluck(:id)
    assert_equal [ first.id, second.id ], route_stops_for_map(stops).pluck(:id)
    assert_equal first.address.label_with_city, route_stops_for_map(stops).first[:label]
  end
end
