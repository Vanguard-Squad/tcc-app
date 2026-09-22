class College < ApplicationRecord
  belongs_to :address
  has_many :students

  accepts_nested_attributes_for :address

  validates :name, presence: true
  validate :zip_code_not_shared_with_another_college

  def label_with_city
    "#{name} - #{address.city}"
  end

  private
    def zip_code_not_shared_with_another_college
      return if address.blank? || address.zip_code.blank?

      duplicate = College.joins(:address).where(addresses: { zip_code: address.zip_code }).where.not(id: id).exists?
      errors.add(:base, "já existe uma faculdade cadastrada com esse CEP") if duplicate
    end
end
