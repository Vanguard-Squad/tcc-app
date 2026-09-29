require "test_helper"

class CheckinTest < ActiveSupport::TestCase
  setup do
    _owner, company = create_company_with_owner!
    @student = create_student!(company: company).student
    @vehicle = create_vehicle!(company: company)
    @checkin = Checkin.today_for!(student: @student, vehicle: @vehicle)
  end

  test "outbound steps run in order and record timestamps" do
    assert_equal "boarded_initial", @checkin.next_step(:outbound)

    @checkin.advance!("boarded_initial", :outbound)
    assert_not_nil @checkin.boarded_initial
    assert_equal "disembarked_college", @checkin.next_step(:outbound)

    @checkin.advance!("disembarked_college", :outbound)
    assert_nil @checkin.next_step(:outbound)
    assert_not @checkin.status
  end

  test "out of order and repeated steps are rejected" do
    assert_raises(Checkin::InvalidStep) { @checkin.advance!("disembarked_college", :outbound) }

    @checkin.advance!("boarded_initial", :outbound)
    assert_raises(Checkin::InvalidStep) { @checkin.advance!("boarded_initial", :outbound) }
  end

  test "return steps are independent of outbound ones and finishing marks status" do
    assert_equal "boarded_college", @checkin.next_step(:return)

    @checkin.advance!("boarded_college", :return)
    @checkin.advance!("disembarked_final", :return)
    assert @checkin.reload.status
  end

  test "an outbound step is not valid for a return trip" do
    assert_raises(KeyError) { Checkin.steps_for(:sideways) }
    assert_not_includes Checkin.steps_for(:return), "boarded_initial"
  end

  test "today_for! reuses the same record during the day" do
    assert_no_difference "Checkin.count" do
      assert_equal @checkin, Checkin.today_for!(student: @student, vehicle: @vehicle)
    end
  end

  test "leg_status reports waiting, boarded and done per direction" do
    assert_equal [ :waiting, nil ], @checkin.leg_status(:outbound)

    @checkin.advance!("boarded_initial", :outbound)
    state, time = @checkin.leg_status(:outbound)
    assert_equal :boarded, state
    assert_not_nil time

    @checkin.advance!("disembarked_college", :outbound)
    assert_equal :done, @checkin.leg_status(:outbound).first
    assert_equal :waiting, @checkin.leg_status(:return).first
  end
end
