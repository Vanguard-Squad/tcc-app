class Stop < ApplicationRecord
  belongs_to :address
  belongs_to :route
end
