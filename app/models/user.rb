class User < ApplicationRecord
  belongs_to :company, optional: true
  has_one :owned_company, class_name: 'Company', foreign_key: 'user_id'
  has_one :student
  has_one :driver
  has_many :archives
  has_many :logs
end
