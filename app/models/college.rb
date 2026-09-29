class College < ApplicationRecord
  belongs_to :address
  has_many :students

  accepts_nested_attributes_for :address

  delegate :company, :company_id, to: :address, allow_nil: true

  validates :name, presence: true
  validate :address_belongs_to_a_company
  validate :zip_code_not_shared_within_company

  def label_with_city
    "#{name} - #{address.city}"
  end

  private
    def address_belongs_to_a_company
      errors.add(:company, "precisa existir") if address.present? && address.company_id.blank?
    end

    def zip_code_not_shared_within_company
      return if address.blank? || address.zip_code.blank? || company_id.blank?

      duplicate = College.joins(:address).where(addresses: { company_id: company_id, zip_code: address.zip_code }).where.not(id: id).exists?
      errors.add(:base, "já existe uma faculdade da sua empresa cadastrada com esse CEP") if duplicate
    end
end
