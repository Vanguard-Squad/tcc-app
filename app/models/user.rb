class User < ApplicationRecord
  has_secure_password

  belongs_to :company, optional: true
  has_one :owned_company, class_name: "Company", foreign_key: "user_id"
  has_one :student
  has_one :driver
  has_many :archives
  has_many :logs

  normalizes :username, with: ->(username) { username.strip.downcase }

  accepts_nested_attributes_for :student
  accepts_nested_attributes_for :driver

  enum :role, { owner: "owner", manager: "manager", student: "student", driver: "driver" }

  validates :name, presence: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, presence: true

  def registration_complete?
    company_id.present?
  end
end
