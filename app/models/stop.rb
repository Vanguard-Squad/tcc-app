class Stop < ApplicationRecord
  belongs_to :address
  belongs_to :route

  accepts_nested_attributes_for :address

  validates :step, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
