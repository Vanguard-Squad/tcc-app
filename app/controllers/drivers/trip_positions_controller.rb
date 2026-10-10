module Drivers
  class TripPositionsController < ApplicationController
    require_role :driver

    def create
      trip = current_user.driver.active_trip
      return head :unprocessable_entity unless trip

      latitude = Float(params[:latitude], exception: false)
      longitude = Float(params[:longitude], exception: false)
      return head :unprocessable_entity unless latitude&.between?(-90, 90) && longitude&.between?(-180, 180)

      accuracy = Float(params[:accuracy], exception: false)
      accuracy = nil unless accuracy&.between?(0, 100_000)

      trip.update_position!(latitude, longitude, accuracy: accuracy&.round(1))
      head :no_content
    end
  end
end
