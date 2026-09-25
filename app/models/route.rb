class Route < ApplicationRecord
  belongs_to :company
  has_many :vehicles
  has_many :stops, -> { order(:step) }

  accepts_nested_attributes_for :stops, allow_destroy: true, reject_if: ->(attrs) {
    attrs["address_id"].blank? &&
      attrs["address_attributes"].present? &&
      attrs["address_attributes"].values.all?(&:blank?)
  }

  validates :name, presence: true, uniqueness: { scope: :company_id }
end
