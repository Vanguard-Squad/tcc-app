class Vehicle < ApplicationRecord
  belongs_to :company
  belongs_to :route, optional: true
  has_many :vehicle_drivers
  has_many :drivers, through: :vehicle_drivers
  has_many :vehicle_students
  has_many :students, through: :vehicle_students
  has_many :checkins
end
