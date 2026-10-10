module Dashboards
  # Painel do dono e da secretaria: o que está rodando agora, o que precisa
  # de atenção e o movimento de hoje.
  class Management
    Alert = Struct.new(:count, :message, :path, keyword_init: true)
    LiveTrip = Struct.new(:trip, :boarded, :total, keyword_init: true)

    attr_reader :company

    def initialize(company)
      @company = company
    end

    def live_trips
      @live_trips ||= Trip.active.where(vehicle: company.vehicles)
        .includes(vehicle: :route, driver: :user).order(:started_at).map do |trip|
          boarded, total = trip.vehicle.route ? RoutePassengerGrouping.new(route: trip.vehicle.route, vehicle: trip.vehicle).boarding_counts(trip.direction) : [ 0, 0 ]
          LiveTrip.new(trip: trip, boarded: boarded, total: total)
        end
    end

    def active_vehicles_count
      vehicles.count(&:is_active?)
    end

    def checkins_today
      @checkins_today ||= Checkin.where(vehicle: company.vehicles, date: Time.current.beginning_of_day)
    end

    def boarded_today_count
      checkins_today.where.not(boarded_initial: nil).or(checkins_today.where.not(boarded_college: nil)).count
    end

    def students_count
      students.size
    end

    # Último registro de cada check-in de hoje, do mais recente para o mais antigo.
    def recent_checkins(limit: 6)
      checkins_today.includes(:vehicle, student: :user).order(updated_at: :desc).limit(limit).filter_map do |checkin|
        step = Checkin::STEPS.select { |name| checkin[name] }.max_by { |name| checkin[name] }
        step && { checkin: checkin, step: step, at: checkin[step] }
      end
    end

    def alerts
      routes = company.routes.includes(:stops, :vehicles).to_a
      active = vehicles.select(&:is_active?)

      [
        Alert.new(count: active.count { |vehicle| vehicle.route_id.nil? }, message: "ônibus ativo(s) sem rota", path: :vehicles_path),
        Alert.new(count: active.count { |vehicle| vehicle.vehicle_drivers.empty? }, message: "ônibus sem motorista na escala", path: :vehicles_path),
        Alert.new(count: students.count { |student| student.vehicle_students.empty? }, message: "aluno(s) sem ônibus", path: :members_path),
        Alert.new(count: students.count { |student| !student.address&.geocoded? }, message: "aluno(s) com endereço sem localização no mapa", path: :members_path),
        Alert.new(count: routes.count { |route| route.stops.empty? }, message: "rota(s) sem paradas", path: :routes_path),
        Alert.new(count: routes.count { |route| route.vehicles.empty? }, message: "rota(s) sem ônibus", path: :routes_path)
      ].select { |alert| alert.count.positive? }
    end

    private
      def vehicles
        @vehicles ||= company.vehicles.includes(:vehicle_drivers).to_a
      end

      def students
        @students ||= Student.joins(:user).where(users: { company_id: company.id, is_active: true })
          .includes(:address, :vehicle_students).to_a
      end
  end
end
