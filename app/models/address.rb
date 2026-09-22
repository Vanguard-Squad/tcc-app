class Address < ApplicationRecord
  has_one :company
  has_one :college
  has_one :student
  has_many :stops

  validates :street, :number, :neighborhood, :city, :country, :zip_code, presence: true

  def label_with_city
    "#{street}, #{number} - #{city}"
  end
end
