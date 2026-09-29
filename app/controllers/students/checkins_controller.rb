module Students
  class CheckinsController < ApplicationController
    require_role :student

    def create
      student = current_user.student
      trip = student&.active_trip
      step = params[:step].to_s

      return redirect_to students_trip_path, alert: "Não há viagem em andamento no seu ônibus." unless trip
      return redirect_to students_trip_path, alert: "Etapa inválida para esta viagem." unless Checkin.steps_for(trip.direction).include?(step)

      Checkin.today_for!(student: student, vehicle: trip.vehicle).advance!(step, trip.direction)
      trip.broadcast_state("checkin")
      redirect_to students_trip_path, notice: "#{Checkin::STEP_LABELS.fetch(step)}: registrado."
    rescue Checkin::InvalidStep => error
      redirect_to students_trip_path, alert: error.message
    end
  end
end
