class HomeController < ApplicationController
  def index
    case current_user.role
    when "owner", "manager"
      @dashboard = Dashboards::Management.new(current_company)
      render :management
    when "driver"
      return render(:empty) unless current_user.driver

      @dashboard = Dashboards::Driver.new(current_user.driver)
      render :driver
    when "student"
      return render(:empty) unless current_user.student

      prepare_student_dashboard
      render :student
    end
  end

  private
    def prepare_student_dashboard
      @student = current_user.student
      @trip = @student.active_trip
      @assignments = @student.vehicle_students.includes(vehicle: :route).to_a
      @vehicle = @trip&.vehicle || @assignments.first&.vehicle
      @stop = @student.nearest_stop_for(@vehicle.route) if @vehicle&.route
      @checkin = Checkin.today_for(student: @student, vehicle: @vehicle) if @vehicle
      @next_step = (@checkin || Checkin.new).next_step(@trip.direction) if @trip
    end
end
