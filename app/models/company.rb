class Company < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "user_id"
  belongs_to :address
  has_many :employees, class_name: "User", foreign_key: "company_id"
  has_many :routes
  has_many :vehicles

  accepts_nested_attributes_for :address

  validates :name, presence: true
  validates :cnpj, presence: true, uniqueness: true
end
