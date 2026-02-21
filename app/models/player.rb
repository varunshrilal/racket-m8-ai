class Player < ApplicationRecord
  validates :name, :suburb, presence: true
  validates :level_label, presence: true, unless: -> { utr.present? }
end
