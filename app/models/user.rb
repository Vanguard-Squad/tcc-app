class User < ApplicationRecord
  has_secure_password

  belongs_to :company, optional: true
  has_one :owned_company, class_name: "Company", foreign_key: "user_id"
  has_one :student
  has_one :driver
  has_many :archives
  has_many :logs

  normalizes :username, with: ->(username) { username.strip.downcase }

  validates :name, presence: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def registration_complete?
    owned_company.present?
  end
end
