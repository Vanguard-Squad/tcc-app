require "test_helper"

class TripChannelTest < ActionCable::Channel::TestCase
  setup do
    _owner, @company = create_company_with_owner!
    @vehicle = create_vehicle!(company: @company)
  end

  test "a student linked to the vehicle can subscribe" do
    user = create_student!(company: @company)
    create_vehicle_student!(vehicle: @vehicle, student: user.student)

    stub_connection current_user: user
    subscribe vehicle_id: @vehicle.id

    assert subscription.confirmed?
    assert_has_stream Trip.stream_name_for(@vehicle.id)
  end

  test "a student from another vehicle is rejected" do
    user = create_student!(company: @company)

    stub_connection current_user: user
    subscribe vehicle_id: @vehicle.id

    assert subscription.rejected?
  end

  test "an assigned driver can subscribe and an unassigned one cannot" do
    assigned = create_driver!(company: @company)
    create_vehicle_driver!(driver: assigned.driver, vehicle: @vehicle)
    other = create_driver!(company: @company)

    stub_connection current_user: assigned
    subscribe vehicle_id: @vehicle.id
    assert subscription.confirmed?

    stub_connection current_user: other
    subscribe vehicle_id: @vehicle.id
    assert subscription.rejected?
  end

  test "managers cannot subscribe" do
    stub_connection current_user: create_manager!(company: @company)
    subscribe vehicle_id: @vehicle.id

    assert subscription.rejected?
  end
end
