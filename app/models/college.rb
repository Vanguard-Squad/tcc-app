class College < ApplicationRecord
  belongs_to :address, optional: true
  has_many :students
end
