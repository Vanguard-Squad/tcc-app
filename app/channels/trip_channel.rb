class TripChannel < ApplicationCable::Channel
  def subscribed
    vehicle = Vehicle.find_by(id: params[:vehicle_id])
    return reject unless vehicle && authorized?(vehicle)

    stream_from Trip.stream_name_for(vehicle.id)
  end

  private
    def authorized?(vehicle)
      user = current_user
      (user.driver? && user.driver.present? && vehicle.vehicle_drivers.exists?(driver: user.driver)) ||
        (user.student? && user.student.present? && vehicle.vehicle_students.exists?(student: user.student))
    end
end
