require "test_helper"

module Drivers
  class TripsControllerTest < ActionDispatch::IntegrationTest
    setup do
      _owner, @company = create_company_with_owner!
      @driver_user = create_driver!(company: @company)
      @vehicle = create_vehicle!(company: @company)
      route = create_route!(company: @company)
      create_stop!(route: route)
      @vehicle.update!(route: route)
      create_vehicle_driver!(driver: @driver_user.driver, vehicle: @vehicle)
    end

    test "driver starts and finishes a trip" do
      sign_in(@driver_user)

      assert_difference "Trip.count", 1 do
        post drivers_trip_url, params: { direction: "outbound" }
      end
      trip = Trip.last
      assert trip.active?
      assert trip.outbound?
      assert_equal @vehicle, trip.vehicle

      delete drivers_trip_url
      assert trip.reload.finished?
    end

    test "cannot start a second trip while one is active" do
      create_trip!(vehicle: @vehicle, driver: @driver_user.driver)
      sign_in(@driver_user)

      assert_no_difference "Trip.count" do
        post drivers_trip_url, params: { direction: "return" }
      end
      assert_redirected_to drivers_route_path
    end

    test "invalid direction is rejected" do
      sign_in(@driver_user)

      assert_no_difference "Trip.count" do
        post drivers_trip_url, params: { direction: "sideways" }
      end
    end

    test "driver without route cannot start a trip" do
      @vehicle.update!(route: nil)
      sign_in(@driver_user)

      assert_no_difference "Trip.count" do
        post drivers_trip_url, params: { direction: "outbound" }
      end
    end

    test "position updates are stored for the active trip and validated" do
      trip = create_trip!(vehicle: @vehicle, driver: @driver_user.driver)
      sign_in(@driver_user)

      post drivers_trip_position_url, params: { latitude: -23.5, longitude: -46.6 }, as: :json
      assert_response :no_content
      assert_equal [ -23.5, -46.6 ], [ trip.reload.latitude, trip.longitude ]

      post drivers_trip_position_url, params: { latitude: "abc", longitude: -46.6 }, as: :json
      assert_response :unprocessable_entity

      post drivers_trip_position_url, params: { latitude: 200, longitude: -46.6 }, as: :json
      assert_response :unprocessable_entity
    end

    test "position without an active trip is rejected" do
      sign_in(@driver_user)

      post drivers_trip_position_url, params: { latitude: -23.5, longitude: -46.6 }, as: :json
      assert_response :unprocessable_entity
    end

    test "students and managers cannot control trips" do
      student = create_student!(company: @company)
      manager = create_manager!(company: @company)

      [ student, manager ].each do |user|
        sign_in(user)
        post drivers_trip_url, params: { direction: "outbound" }
        assert_redirected_to root_path
      end
    end
  end
end
