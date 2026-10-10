module Students
  # Check-in pela leitura do QR code exibido no celular do motorista. O código
  # leva a esta tela, onde o aluno confirma a próxima etapa da viagem.
  class QrCheckinsController < ApplicationController
    require_role :student

    before_action :set_trip_and_step

    def show
    end

    def create
      Checkin.today_for!(student: @student, vehicle: @trip.vehicle).advance!(@step, @trip.direction)
      @trip.broadcast_state("checkin")
      audit("checkin.qr_registered", @trip, etapa: Checkin::STEP_LABELS.fetch(@step))
      redirect_to students_trip_path, notice: "#{Checkin::STEP_LABELS.fetch(@step)}: registrado pelo QR code."
    rescue Checkin::InvalidStep => error
      redirect_to students_trip_path, alert: error.message
    end

    private
      def set_trip_and_step
        @student = current_user.student
        @trip = Trip.find_by_qr_checkin_token(params[:token])

        unless @trip&.active?
          return redirect_to students_trip_path, alert: "QR code inválido ou expirado. Leia o código novamente."
        end

        unless @student&.vehicle_students&.exists?(vehicle_id: @trip.vehicle_id, is_return: @trip.return_trip?)
          return redirect_to students_trip_path, alert: "Este QR code é de um ônibus ou viagem em que você não está."
        end

        checkin = Checkin.today_for(student: @student, vehicle: @trip.vehicle) || Checkin.new
        @step = checkin.next_step(@trip.direction)
        redirect_to students_trip_path, notice: "Todas as etapas desta viagem já foram registradas." unless @step
      end
  end
end
