class Checkin < ApplicationRecord
  belongs_to :vehicle
  belongs_to :student
end
