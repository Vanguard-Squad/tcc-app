class Stop < ApplicationRecord
  belongs_to :address
  belongs_to :route

  accepts_nested_attributes_for :address

  before_validation :assign_company_to_new_address
  validates :step, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :address_belongs_to_route_company

  private
    def assign_company_to_new_address
      address.company ||= route&.company if address&.new_record?
    end

    def address_belongs_to_route_company
      return if address.blank? || route.blank?

      errors.add(:address, "não pertence à sua empresa") if address.company_id != route.company_id
    end
end
