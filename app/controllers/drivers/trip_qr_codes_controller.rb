module Drivers
  class TripQrCodesController < ApplicationController
    require_role :driver

    REFRESH_SECONDS = 60

    def show
      @trip = current_user.driver.active_trip
      return redirect_to drivers_route_path, alert: "Inicie uma viagem para exibir o QR code de check-in." unless @trip

      @checkin_url = students_qr_checkin_url(token: @trip.qr_checkin_token)
    end
  end
end
