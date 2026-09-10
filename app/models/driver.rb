class Driver < ApplicationRecord
  belongs_to :user
  has_many :vehicle_drivers
  has_many :vehicles, through: :vehicle_drivers

  validates :drive_license, presence: true, uniqueness: true
end
