class College < ApplicationRecord
  belongs_to :address
  has_many :students
end
