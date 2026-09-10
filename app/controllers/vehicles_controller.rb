class VehiclesController < ApplicationController
  require_role :owner, :manager

  def index
    @vehicles = current_company.vehicles.order(:license_plate)
  end

  def new
    @vehicle = Vehicle.new
  end

  def create
    @vehicle = current_company.vehicles.new(vehicle_params)

    if @vehicle.save
      redirect_to vehicles_path, notice: "Ônibus cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def vehicle_params
      params.require(:vehicle).permit(:license_plate, :seats)
    end
end
