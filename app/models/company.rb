class Company < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "user_id"
  belongs_to :address
  has_many :employees, class_name: "User", foreign_key: "company_id"
  has_many :routes
  has_many :vehicles
  has_many :addresses
  has_many :colleges, through: :addresses

  accepts_nested_attributes_for :address

  after_create :claim_address

  validates :name, presence: true
  validates :cnpj, presence: true, uniqueness: true

  private
    # O endereço da empresa é criado antes dela existir; só agora dá para ligá-lo.
    def claim_address
      address.update_column(:company_id, id)
    end
end
