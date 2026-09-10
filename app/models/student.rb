class Student < ApplicationRecord
  belongs_to :user
  belongs_to :address
  belongs_to :college
  has_many :vehicle_students
  has_many :vehicles, through: :vehicle_students
  has_many :checkins

  accepts_nested_attributes_for :address

  validates :cpf, presence: true, uniqueness: true
end
