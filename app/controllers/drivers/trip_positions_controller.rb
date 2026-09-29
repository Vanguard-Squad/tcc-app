module Drivers
  class TripPositionsController < ApplicationController
    require_role :driver

    def create
      trip = current_user.driver.active_trip
      return head :unprocessable_entity unless trip

      latitude = Float(params[:latitude], exception: false)
      longitude = Float(params[:longitude], exception: false)
      return head :unprocessable_entity unless latitude&.between?(-90, 90) && longitude&.between?(-180, 180)

      trip.update_position!(latitude, longitude)
      head :no_content
    end
  end
end
