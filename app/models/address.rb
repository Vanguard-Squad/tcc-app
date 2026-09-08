class Address < ApplicationRecord
  has_one :company
  has_one :college
  has_one :student
  has_many :stops
end
