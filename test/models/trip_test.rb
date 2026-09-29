require "test_helper"

class TripTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    _owner, company = create_company_with_owner!
    @driver = create_driver!(company: company).driver
    @vehicle = create_vehicle!(company: company)
  end

  test "the driver must be assigned to the vehicle" do
    unassigned = create_driver!(company: @vehicle.company).driver
    trip = Trip.new(vehicle: @vehicle, driver: unassigned, direction: :outbound, status: :active, started_at: Time.current)

    assert_not trip.valid?
    assert_includes trip.errors[:driver], "não está vinculado a este ônibus"
  end

  test "a vehicle cannot have two active trips" do
    create_trip!(vehicle: @vehicle, driver: @driver)

    duplicate = Trip.new(vehicle: @vehicle, driver: @driver, direction: :return_trip, status: :active, started_at: Time.current)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:vehicle], "já tem uma viagem em andamento"
  end

  test "a new trip can start after the previous one finished" do
    create_trip!(vehicle: @vehicle, driver: @driver).finish!

    assert create_trip!(vehicle: @vehicle, driver: @driver, direction: :return_trip).persisted?
  end

  test "update_position! stores the position and broadcasts it" do
    trip = create_trip!(vehicle: @vehicle, driver: @driver)

    assert_broadcasts Trip.stream_name_for(@vehicle.id), 1 do
      trip.update_position!(-23.56, -46.66)
    end

    assert_equal [ -23.56, -46.66 ], [ trip.reload.latitude, trip.longitude ]
    assert_not_nil trip.position_at
  end

  test "finish! ends the trip and broadcasts" do
    trip = create_trip!(vehicle: @vehicle, driver: @driver)

    assert_broadcasts Trip.stream_name_for(@vehicle.id), 1 do
      trip.finish!
    end

    assert trip.reload.finished?
    assert_not_nil trip.finished_at
  end
end
