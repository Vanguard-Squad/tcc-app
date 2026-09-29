require "test_helper"

module Students
  class TripsControllerTest < ActionDispatch::IntegrationTest
    setup do
      _owner, @company = create_company_with_owner!
      @driver = create_driver!(company: @company).driver
      @vehicle = create_vehicle!(company: @company)
      @route = create_route!(company: @company)
      @stop = create_stop!(route: @route)
      @vehicle.update!(route: @route)
      create_vehicle_driver!(driver: @driver, vehicle: @vehicle)

      @student_user = create_student!(company: @company)
      @student = @student_user.student
      create_vehicle_student!(vehicle: @vehicle, student: @student, is_return: false)
    end

    test "student sees the boarding point and the empty trip state" do
      sign_in(@student_user)
      get students_trip_url

      assert_response :success
      assert_match @route.name, response.body
      assert_match "Nenhuma viagem em andamento", response.body
      assert_select "form[action='#{students_checkins_path}']", count: 0
    end

    test "student without a vehicle sees an empty state" do
      other = create_student!(company: @company)
      sign_in(other)

      get students_trip_url
      assert_response :success
      assert_match "não está vinculado", response.body
    end

    test "check-in button appears only with an active trip and walks through the outbound steps" do
      create_trip!(vehicle: @vehicle, driver: @driver, direction: :outbound)
      sign_in(@student_user)

      get students_trip_url
      assert_select "form[action='#{students_checkins_path}'] button", text: "Embarquei no ônibus"

      post students_checkins_url, params: { step: "boarded_initial" }
      assert_redirected_to students_trip_path
      follow_redirect!
      assert_select "form[action='#{students_checkins_path}'] button", text: "Cheguei na faculdade"

      post students_checkins_url, params: { step: "disembarked_college" }
      checkin = Checkin.today_for(student: @student, vehicle: @vehicle)
      assert_not_nil checkin.boarded_initial
      assert_not_nil checkin.disembarked_college
    end

    test "a check-in broadcasts so the driver's screen refreshes" do
      create_trip!(vehicle: @vehicle, driver: @driver, direction: :outbound)
      sign_in(@student_user)

      assert_broadcasts Trip.stream_name_for(@vehicle.id), 1 do
        post students_checkins_url, params: { step: "boarded_initial" }
      end
    end

    test "check-in without an active trip is rejected" do
      sign_in(@student_user)

      assert_no_difference "Checkin.count" do
        post students_checkins_url, params: { step: "boarded_initial" }
      end
      assert_redirected_to students_trip_path
      assert_equal "Não há viagem em andamento no seu ônibus.", flash[:alert]
    end

    test "out of order and wrong-direction steps are rejected" do
      create_trip!(vehicle: @vehicle, driver: @driver, direction: :outbound)
      sign_in(@student_user)

      post students_checkins_url, params: { step: "disembarked_college" }
      assert_equal "Etapa fora de ordem.", flash[:alert]

      post students_checkins_url, params: { step: "boarded_college" }
      assert_equal "Etapa inválida para esta viagem.", flash[:alert]
      assert_nil Checkin.today_for(student: @student, vehicle: @vehicle)&.boarded_college
    end

    test "a trip in a direction the student is not assigned to does not enable check-in" do
      create_trip!(vehicle: @vehicle, driver: @driver, direction: :return_trip)
      sign_in(@student_user)

      post students_checkins_url, params: { step: "boarded_college" }
      assert_equal "Não há viagem em andamento no seu ônibus.", flash[:alert]
    end

    test "a student from another vehicle cannot check in on this trip" do
      create_trip!(vehicle: @vehicle, driver: @driver, direction: :outbound)
      outsider = create_student!(company: @company)
      sign_in(outsider)

      assert_no_difference "Checkin.count" do
        post students_checkins_url, params: { step: "boarded_initial" }
      end
    end

    test "drivers and managers cannot access the student area" do
      manager = create_manager!(company: @company)

      [ create_driver!(company: @company), manager ].each do |user|
        sign_in(user)
        get students_trip_url
        assert_redirected_to root_path
      end
    end
  end
end
