class Address < ApplicationRecord
  has_one :company
  has_one :college
  has_one :student
  has_many :stops

  validates :street, :number, :neighborhood, :country, :zip_code, presence: true
end
