class Chat < ApplicationRecord
  belongs_to :topic
  belongs_to :user
  has_many :messages, dependent: :destroy
  DEFAULT_TITLE = "Untitled"
end
