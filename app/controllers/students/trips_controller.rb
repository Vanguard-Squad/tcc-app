module Students
  class TripsController < ApplicationController
    require_role :student

    TARGET_BY_STEP = {
      "boarded_initial" => :stop, "disembarked_college" => :college,
      "boarded_college" => :college, "disembarked_final" => :stop
    }.freeze

    before_action :set_student

    def show
      @trip = @student.active_trip
      @vehicle = @trip&.vehicle || @student.vehicle_students.includes(vehicle: :route).first&.vehicle
      @route = @vehicle&.route
      return unless @route

      @stop = @student.nearest_stop_for(@route)
      @checkin = Checkin.today_for(student: @student, vehicle: @vehicle)
      return unless @trip

      @next_step = (@checkin || Checkin.new).next_step(@trip.direction)
      @target = tracking_target
    end

    private
      def set_student
        @student = current_user.student
        redirect_to root_path, alert: "Perfil de aluno não encontrado." unless @student
      end

      # Para onde o ônibus está indo, do ponto de vista do aluno: ao ponto de
      # embarque/desembarque ou à faculdade, conforme a etapa atual.
      def tracking_target
        kind = TARGET_BY_STEP[@next_step]
        address = case kind
        when :stop then @stop&.address
        when :college then @student.college.address
        end
        return unless address&.geocoded?

        { kind: kind, lat: address.latitude, lng: address.longitude, label: address.label_with_city }
      end
  end
end
