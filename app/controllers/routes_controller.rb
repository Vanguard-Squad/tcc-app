class RoutesController < ApplicationController
  require_role :owner, :manager

  def index
    @routes = current_company.routes.includes(stops: :address).order(:name)
  end

  def new
    @route = current_company.routes.new
    @route.stops.build
    load_stop_address_options
  end

  def create
    @route = current_company.routes.new(route_params)
    assign_stop_order

    if @route.save
      redirect_to routes_path, notice: "Rota cadastrada com sucesso."
    else
      load_stop_address_options
      render :new, status: :unprocessable_entity
    end
  end

  private
    def route_params
      params.require(:route).permit(
        :name,
        stops_attributes: [
          :address_id,
          address_attributes: %i[street number complement neighborhood city country zip_code]
        ]
      )
    end

    # As paradas são enumeradas pela ordem em que aparecem no formulário
    # (início -> fim), não por um campo digitado pelo usuário.
    def assign_stop_order
      @route.stops.each_with_index { |stop, index| stop.step = index + 1 }
    end

    # Paradas não têm tela própria de cadastro: reaproveita endereços já
    # usados como parada em outras rotas desta company, ou permite criar um novo.
    def load_stop_address_options
      @stop_addresses = Address.joins(stops: :route)
                                .where(routes: { company_id: current_company.id })
                                .distinct
                                .order(:street)
    end
end
