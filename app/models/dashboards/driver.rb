module Dashboards
  # Painel do motorista: ônibus e rota de hoje, viagem em andamento e escala.
  class Driver
    attr_reader :driver

    def initialize(driver)
      @driver = driver
    end

    def vehicle
      @vehicle ||= driver.current_vehicle
    end

    def route
      vehicle&.route
    end

    def stops
      @stops ||= route ? route.stops.includes(:address).to_a : []
    end

    def active_trip
      @active_trip ||= driver.active_trip
    end

    def grouping
      @grouping ||= RoutePassengerGrouping.new(route: route, vehicle: vehicle) if route
    end

    # Passageiros por trecho: [embarcados, total].
    def counts(direction)
      grouping ? grouping.boarding_counts(direction) : [ 0, 0 ]
    end

    # Escala da semana: dia => placa (dias sem ônibus ficam de fora).
    def schedule
      by_day = driver.vehicle_drivers.includes(:vehicle).group_by(&:week_day)
      ::Driver::WEEK_DAYS.filter_map do |day|
        assignment = by_day[day]&.first
        [ day, assignment.vehicle ] if assignment
      end
    end

    def today
      ::Driver::WEEK_DAYS[Date.current.wday]
    end
  end
end
