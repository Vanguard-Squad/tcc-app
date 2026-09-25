module Drivers
  class RoutesController < ApplicationController
    require_role :driver

    before_action :set_vehicle_and_route

    def show
      @stops = @route&.stops&.includes(:address) || []
    end

    def passengers
      @grouping = RoutePassengerGrouping.new(route: @route, vehicle: @vehicle) if @route
    end

    def edit
      @stops = @route&.stops&.includes(:address) || []
      redirect_to drivers_route_path, alert: "Nenhuma rota atribuída." unless @route
    end

    def update
      return redirect_to drivers_route_path, alert: "Nenhuma rota atribuída." unless @route

      ordered_ids = Array(params[:stop_ids]).map(&:to_i)
      if ordered_ids.sort == @route.stops.pluck(:id).sort
        Stop.transaction { ordered_ids.each_with_index { |id, index| Stop.where(id: id).update_all(step: index + 1) } }
        redirect_to drivers_route_path, notice: "Ordem das paradas atualizada."
      else
        redirect_to edit_drivers_route_path, alert: "Não foi possível salvar a nova ordem."
      end
    end

    private
      def set_vehicle_and_route
        @vehicle = current_user.driver.current_vehicle
        @route = @vehicle&.route
      end
  end
end
