class Driver < ApplicationRecord
  WEEK_DAYS = %w[domingo segunda terca quarta quinta sexta sabado].freeze

  belongs_to :user
  has_many :vehicle_drivers
  has_many :vehicles, through: :vehicle_drivers

  validates :drive_license, presence: true, uniqueness: true

  # Veículo do dia (por vehicle_drivers.week_day), ou o primeiro vínculo caso
  # não haja um específico para hoje. nil quando o motorista não tem veículo.
  def current_vehicle
    today = WEEK_DAYS[Date.current.wday]
    vehicle_drivers.find_by(week_day: today)&.vehicle || vehicle_drivers.first&.vehicle
  end
end
