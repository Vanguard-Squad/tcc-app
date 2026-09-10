class Vehicle < ApplicationRecord
  belongs_to :company
  belongs_to :route, optional: true
  has_many :vehicle_drivers
  has_many :drivers, through: :vehicle_drivers
  has_many :vehicle_students
  has_many :students, through: :vehicle_students
  has_many :checkins

  validates :license_plate, presence: true, uniqueness: true
  validates :seats, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
