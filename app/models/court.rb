class Court < ApplicationRecord
  validates :name, :suburb, :surface, presence: true
end
