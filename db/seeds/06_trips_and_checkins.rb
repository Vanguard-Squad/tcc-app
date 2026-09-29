# Viagens e check-ins. Cobre:
#  - viagem ATIVA (ônibus 2, ida) com posição e um aluno já embarcado;
#  - ônibus 1 sem viagem ativa, para testar "Iniciar viagem" como José;
#  - histórico de ontem: viagens finalizadas e check-ins completos, parciais
#    e só de volta.
jose = Seeds.data.fetch(:jose)
marcos = Seeds.data.fetch(:marcos)
vehicle_1 = Seeds.data.fetch(:vehicle_1)
vehicle_2 = Seeds.data.fetch(:vehicle_2)
yesterday = Time.current.yesterday.beginning_of_day

# --- Viagem ativa (ônibus 2) ---
trip = Trip.find_or_initialize_by(vehicle: vehicle_2, status: "active")
trip.assign_attributes(
  driver: marcos, direction: :outbound, started_at: 10.minutes.ago,
  latitude: -23.5484232, longitude: -46.6508633, position_at: Time.current
)
trip.save!

def checkin!(student, vehicle, date, **steps)
  Checkin.find_or_initialize_by(student: student, vehicle: vehicle, date: date).tap do |checkin|
    checkin.assign_attributes(steps)
    checkin.status = checkin.disembarked_final.present?
    checkin.save!
  end
end

checkin!(Seeds.data.fetch(:fabio), vehicle_2, Time.current.beginning_of_day, boarded_initial: 5.minutes.ago)

# --- Histórico de ontem (ônibus 1, José) ---
[ [ :outbound, 7 ], [ :return_trip, 17 ] ].each do |direction, hour|
  past = Trip.find_or_initialize_by(vehicle: vehicle_1, driver: jose, direction: direction, status: "finished")
  past.assign_attributes(started_at: yesterday.change(hour: hour), finished_at: yesterday.change(hour: hour, min: 50))
  past.save!
end

at = ->(hour, minute) { yesterday.change(hour: hour, min: minute) }
checkin!(Seeds.data.fetch(:ana), vehicle_1, yesterday,
         boarded_initial: at.call(7, 12), disembarked_college: at.call(7, 48),
         boarded_college: at.call(17, 5), disembarked_final: at.call(17, 42))
checkin!(Seeds.data.fetch(:bruno), vehicle_1, yesterday, boarded_initial: at.call(7, 15), disembarked_college: at.call(7, 48))
checkin!(Seeds.data.fetch(:carla), vehicle_1, yesterday, boarded_college: at.call(17, 6), disembarked_final: at.call(17, 40))
