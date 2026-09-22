class User < ApplicationRecord
  has_secure_password

  belongs_to :company, optional: true
  has_one :owned_company, class_name: "Company", foreign_key: "user_id"
  has_one :student
  has_one :driver
  has_many :archives
  has_many :logs

  normalizes :email, with: ->(email) { email.strip.downcase }

  accepts_nested_attributes_for :student
  accepts_nested_attributes_for :driver

  enum :role, { owner: "owner", manager: "manager", student: "student", driver: "driver" }

  PASSWORD_FORMAT = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9\s]).{8,}\z/

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, format: {
    with: PASSWORD_FORMAT,
    message: "precisa ter no mínimo 8 caracteres, com letra maiúscula, minúscula e caractere especial"
  }, allow_nil: true
  validates :role, presence: true

  def registration_complete?
    company_id.present?
  end
end
