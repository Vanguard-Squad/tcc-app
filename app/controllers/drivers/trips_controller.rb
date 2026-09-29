module Drivers
  class TripsController < ApplicationController
    require_role :driver

    def create
      driver = current_user.driver
      vehicle = driver.current_vehicle

      if vehicle.nil? || vehicle.route.nil?
        return redirect_to drivers_route_path, alert: "Você não tem ônibus com rota atribuída."
      end

      trip = Trip.new(vehicle: vehicle, driver: driver, direction: params[:direction], status: :active, started_at: Time.current)

      if trip.save
        trip.broadcast_state("started")
        redirect_to drivers_route_path, notice: "Viagem iniciada."
      else
        redirect_to drivers_route_path, alert: trip.errors.full_messages.to_sentence
      end
    rescue ArgumentError
      redirect_to drivers_route_path, alert: "Direção da viagem inválida."
    end

    def destroy
      trip = current_user.driver.active_trip
      trip&.finish!
      redirect_to drivers_route_path, notice: "Viagem finalizada."
    end
  end
end
