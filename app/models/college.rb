class College < ApplicationRecord
  belongs_to :address
  has_many :students

  accepts_nested_attributes_for :address

  validates :name, presence: true
end
