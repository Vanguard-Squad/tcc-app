class Student < ApplicationRecord
  belongs_to :user
  belongs_to :address
  belongs_to :college
  has_many :vehicle_students
  has_many :vehicles, through: :vehicle_students
  has_many :checkins
end
