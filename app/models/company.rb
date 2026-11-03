class Company < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: "user_id"
  belongs_to :address
  has_many :employees, class_name: "User", foreign_key: "company_id"
  has_many :routes
  has_many :vehicles
  has_many :addresses
  has_many :colleges, through: :addresses
  # Contrato que cada aluno baixa, assina pelo gov.br e devolve.
  has_one_attached :contract_template

  accepts_nested_attributes_for :address

  after_create :claim_address

  validates :name, presence: true
  validates :cnpj, presence: true, uniqueness: true
  validates :contract_template, pdf_attachment: { label: "O modelo de contrato" }

  private
    # O endereço da empresa é criado antes dela existir; só agora dá para ligá-lo.
    def claim_address
      address.update_column(:company_id, id)
    end
end
