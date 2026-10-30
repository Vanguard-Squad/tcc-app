class RoutesController < ApplicationController
  require_role :owner, :manager

  before_action :set_route, only: %i[edit update]

  # Pendências apontadas no painel "Precisa de atenção" do início.
  ISSUES = { "sem-paradas" => "Rotas sem paradas", "sem-onibus" => "Rotas sem ônibus" }.freeze

  def index
    @routes = current_company.routes.includes(:vehicles, stops: :address).order(:name)
    @issue = params[:pendencia].presence_in(ISSUES.keys)
    @routes = @routes.where.missing(@issue == "sem-paradas" ? :stops : :vehicles) if @issue
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
      audit("route.created", @route)
      redirect_to routes_path, notice: "Rota cadastrada com sucesso."
    else
      load_stop_address_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_stop_address_options
  end

  def update
    @route.assign_attributes(route_params)
    assign_stop_order

    if @route.save
      audit("route.updated", @route, **Log.changes_of(@route), paradas: @route.stops.size)
      redirect_to routes_path, notice: "Rota atualizada com sucesso."
    else
      load_stop_address_options
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_route
      @route = current_company.routes.includes(stops: :address).find(params[:id])
    end

    def route_params
      params.require(:route).permit(
        :name,
        stops_attributes: [
          :id,
          :_destroy,
          :address_id,
          address_attributes: %i[street number complement neighborhood city country zip_code]
        ]
      )
    end

    # As paradas são enumeradas pela ordem em que aparecem no formulário
    # (início -> fim), não por um campo digitado pelo usuário. Paradas
    # removidas não entram na contagem.
    def assign_stop_order
      @route.stops.reject(&:marked_for_destruction?).each_with_index { |stop, index| stop.step = index + 1 }
    end

    # Paradas não têm tela própria de cadastro: reaproveita endereços já
    # usados como parada em outras rotas desta company, ou permite criar um novo.
    def load_stop_address_options
      @stop_addresses = current_company.addresses.joins(:stops).distinct.order(:street)
    end
end
