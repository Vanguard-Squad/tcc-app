class Company < ApplicationRecord
  belongs_to :owner, class_name: 'User', foreign_key: 'user_id'
  belongs_to :address, optional: true
  has_many :employees, class_name: 'User', foreign_key: 'company_id'
  has_many :routes
  has_many :vehicles
end
