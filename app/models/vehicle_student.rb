class VehicleStudent < ApplicationRecord
  belongs_to :vehicle
  belongs_to :student
end
