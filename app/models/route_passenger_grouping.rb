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

  # Check-in de hoje do aluno neste ônibus (nil se ainda não houve registro).
  def checkin_for(student)
    todays_checkins[student.id]
  end

  # Quantos alunos do trecho já embarcaram (ou concluíram) e o total.
  def boarding_counts(direction)
    leg = direction.to_s == "outbound" ? outbound : return_leg
    students = leg[:grouped].flat_map { |_stop, entries| entries.map(&:student) } + leg[:unmatched]
    boarded = students.count { |student| checkin_for(student)&.leg_status(direction)&.first.to_s.in?(%w[boarded done]) }
    [ boarded, students.size ]
  end

  private
    def todays_checkins
      @todays_checkins ||= Checkin.where(vehicle_id: @vehicle.id, date: Time.current.beginning_of_day).index_by(&:student_id)
    end

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
