class Route < ApplicationRecord
  belongs_to :company
  has_many :vehicles
  has_many :stops
end
