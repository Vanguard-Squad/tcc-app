class Trip < ApplicationRecord
  # Validade de cada QR code de check-in; a tela do motorista troca o código antes disso.
  QR_CHECKIN_TTL = 2.minutes

  belongs_to :vehicle
  belongs_to :driver

  enum :direction, { outbound: "outbound", return_trip: "return" }
  enum :status, { active: "active", finished: "finished" }

  validates :direction, :started_at, presence: true
  validate :driver_assigned_to_vehicle
  validate :single_active_trip_per_vehicle, if: :active?

  def self.stream_name_for(vehicle_id)
    "vehicle:#{vehicle_id}:trip"
  end

  def self.find_by_qr_checkin_token(token)
    find_signed(token.to_s, purpose: :qr_checkin)
  end

  def qr_checkin_token
    signed_id(purpose: :qr_checkin, expires_in: QR_CHECKIN_TTL)
  end

  # A precisão (raio em metros informado pelo GPS) só vai para quem está
  # acompanhando ao vivo; não é guardada.
  def update_position!(latitude, longitude, accuracy: nil)
    update!(latitude: latitude, longitude: longitude, position_at: Time.current)
    broadcast_state("position", accuracy: accuracy)
  end

  def finish!
    update!(status: :finished, finished_at: Time.current)
    broadcast_state("finished")
  end

  def broadcast_state(event, **extra)
    ActionCable.server.broadcast(self.class.stream_name_for(vehicle_id), state.merge(event: event, **extra.compact))
  end

  def state
    { trip_id: id, status: status, direction: direction, lat: latitude, lng: longitude, position_at: position_at&.iso8601 }
  end

  private
    def driver_assigned_to_vehicle
      return if vehicle.blank? || driver.blank?

      errors.add(:driver, "não está vinculado a este ônibus") unless vehicle.vehicle_drivers.exists?(driver_id: driver_id)
    end

    def single_active_trip_per_vehicle
      others = Trip.active.where(vehicle_id: vehicle_id).where.not(id: id)
      errors.add(:vehicle, "já tem uma viagem em andamento") if others.exists?
    end
end
