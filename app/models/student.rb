class Student < ApplicationRecord
  belongs_to :user
  belongs_to :address
  belongs_to :college
  has_many :vehicle_students
  has_many :vehicles, through: :vehicle_students
  has_many :checkins

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :college, reject_if: :all_blank

  validates :cpf, presence: true, uniqueness: true

  # Parada da rota mais próxima do endereço do aluno: embarque na ida,
  # desembarque na volta. Retorna nil se o aluno ou nenhuma parada da rota
  # tiver coordenadas (endereço ainda não geocodificado).
  def nearest_stop_for(route)
    return nil unless address&.geocoded?

    geocoded_stops = route.stops.select { |stop| stop.address&.geocoded? }
    return nil if geocoded_stops.empty?

    geocoded_stops.min_by { |stop| address.distance_to([ stop.address.latitude, stop.address.longitude ]) }
  end
end
