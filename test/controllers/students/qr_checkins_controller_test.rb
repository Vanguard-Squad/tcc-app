require "test_helper"

module Students
  class QrCheckinsControllerTest < ActionDispatch::IntegrationTest
    setup do
      _owner, @company = create_company_with_owner!
      @driver_user = create_driver!(company: @company)
      @vehicle = create_vehicle!(company: @company)
      @vehicle.update!(route: create_route!(company: @company))
      @trip = create_trip!(vehicle: @vehicle, driver: @driver_user.driver, direction: :outbound)

      @student_user = create_student!(company: @company)
      @student = @student_user.student
      create_vehicle_student!(vehicle: @vehicle, student: @student, is_return: false)
    end

    test "driver sees a QR code pointing to the check-in page" do
      sign_in(@driver_user)
      get drivers_trip_qr_code_url

      assert_response :success
      assert_select "[data-controller='qr-code'][data-qr-code-text-value*='/aluno/checkin/qr?token=']"
    end

    test "driver without an active trip is sent back to the route" do
      @trip.finish!
      sign_in(@driver_user)

      get drivers_trip_qr_code_url
      assert_redirected_to drivers_route_path
    end

    test "scanning the code shows the next step and confirming registers it" do
      token = @trip.qr_checkin_token
      sign_in(@student_user)

      get students_qr_checkin_url(token: token)
      assert_response :success
      assert_select "button", text: "Embarquei no ônibus"

      assert_broadcasts Trip.stream_name_for(@vehicle.id), 1 do
        post students_qr_checkin_url, params: { token: token }
      end
      assert_redirected_to students_trip_path
      assert_not_nil Checkin.today_for(student: @student, vehicle: @vehicle).boarded_initial
      assert Log.exists?(action: "checkin.qr_registered", user: @student_user, auditable: @trip)

      post students_qr_checkin_url, params: { token: token }
      assert_not_nil Checkin.today_for(student: @student, vehicle: @vehicle).disembarked_college
    end

    test "expired or tampered codes are rejected" do
      token = @trip.qr_checkin_token
      sign_in(@student_user)

      travel Trip::QR_CHECKIN_TTL + 1.second do
        post students_qr_checkin_url, params: { token: token }
      end
      assert_equal "QR code inválido ou expirado. Leia o código novamente.", flash[:alert]

      post students_qr_checkin_url, params: { token: "#{token}x" }
      assert_equal "QR code inválido ou expirado. Leia o código novamente.", flash[:alert]
      assert_nil Checkin.today_for(student: @student, vehicle: @vehicle)
    end

    test "a code from a finished trip is rejected" do
      token = @trip.qr_checkin_token
      @trip.finish!
      sign_in(@student_user)

      post students_qr_checkin_url, params: { token: token }
      assert_equal "QR code inválido ou expirado. Leia o código novamente.", flash[:alert]
    end

    test "students from another vehicle cannot use the code" do
      outsider = create_student!(company: @company)
      sign_in(outsider)

      assert_no_difference "Checkin.count" do
        post students_qr_checkin_url, params: { token: @trip.qr_checkin_token }
      end
      assert_equal "Este QR code é de um ônibus ou viagem em que você não está.", flash[:alert]
    end

    test "scanning while logged out returns to the check-in page after login" do
      url = students_qr_checkin_path(token: @trip.qr_checkin_token)

      get url
      assert_redirected_to login_path

      sign_in(@student_user)
      assert_redirected_to url
    end
  end
end
