class VehiclesController < ApplicationController
  require_role :owner, :manager

  before_action :set_vehicle, only: %i[edit update]
  before_action :load_routes, only: %i[new create edit update]

  def index
    @vehicles = current_company.vehicles.includes(:route, :vehicle_students, drivers: :user).order(:license_plate)
    @live_vehicle_ids = Trip.active.where(vehicle: @vehicles).pluck(:vehicle_id).to_set
  end

  def new
    @vehicle = Vehicle.new
  end

  def create
    @vehicle = current_company.vehicles.new(vehicle_params)

    if @vehicle.save
      audit("vehicle.created", @vehicle)
      redirect_to vehicles_path, notice: "Ônibus cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @vehicle.update(vehicle_params)
      audit("vehicle.updated", @vehicle, **Log.changes_of(@vehicle))
      redirect_to vehicles_path, notice: "Ônibus atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_vehicle
      @vehicle = current_company.vehicles.find(params[:id])
    end

    def load_routes
      @routes = current_company.routes.order(:name)
    end

    def vehicle_params
      params.require(:vehicle).permit(:license_plate, :seats, :route_id)
    end
end
