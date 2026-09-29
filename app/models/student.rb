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
  before_validation :assign_company_to_new_address
  validate :college_belongs_to_user_company
  validate :address_belongs_to_user_company

  # Viagem em andamento em algum ônibus do aluno, na direção (ida/volta) em
  # que ele está vinculado.
  def active_trip
    Trip.active.where(vehicle_id: vehicle_students.select(:vehicle_id)).includes(:vehicle).detect do |trip|
      vehicle_students.exists?(vehicle_id: trip.vehicle_id, is_return: trip.return_trip?)
    end
  end

  # Parada da rota mais próxima do endereço do aluno: embarque na ida,
  # desembarque na volta. Retorna nil se o aluno ou nenhuma parada da rota
  # tiver coordenadas (endereço ainda não geocodificado).
  def nearest_stop_for(route)
    return nil unless address&.geocoded?

    geocoded_stops = route.stops.select { |stop| stop.address&.geocoded? }
    return nil if geocoded_stops.empty?

    geocoded_stops.min_by { |stop| address.distance_to([ stop.address.latitude, stop.address.longitude ]) }
  end

  private
    def assign_company_to_new_address
      address.company ||= user&.company if address&.new_record?
    end

    def college_belongs_to_user_company
      return if college.blank? || user&.company_id.blank?

      errors.add(:college, "não pertence à sua empresa") if college.company_id != user.company_id
    end

    def address_belongs_to_user_company
      return if address.blank? || user&.company_id.blank?

      errors.add(:address, "não pertence à sua empresa") if address.company_id != user.company_id
    end
end
