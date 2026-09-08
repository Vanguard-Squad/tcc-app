class Student < ApplicationRecord
  belongs_to :user
  belongs_to :address, optional: true
  belongs_to :college, optional: true
  has_many :vehicle_students
  has_many :vehicles, through: :vehicle_students
  has_many :checkins
end
