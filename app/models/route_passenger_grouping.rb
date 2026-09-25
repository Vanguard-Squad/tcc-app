# Agrupa os passageiros de um veículo/rota por parada mais próxima de casa,
# separando ida (embarque na parada, desembarque na faculdade) de volta
# (embarque na faculdade, desembarque na parada).
class RoutePassengerGrouping
  Entry = Struct.new(:student, :stop, keyword_init: true)

  def initialize(route:, vehicle:)
    @route = route
    @vehicle = vehicle
  end

  def outbound
    group(is_return: false)
  end

  def return_leg
    group(is_return: true)
  end

  private
    def group(is_return:)
      students = @vehicle.students
                          .merge(VehicleStudent.where(is_return: is_return))
                          .includes(:address, :college, :user)

      entries = students.map { |student| Entry.new(student: student, stop: student.nearest_stop_for(@route)) }
      matched, unmatched = entries.partition(&:stop)

      {
        grouped: matched.group_by(&:stop).sort_by { |stop, _| stop.step },
        unmatched: unmatched.map(&:student)
      }
    end
end
