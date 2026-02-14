class Topic < ApplicationRecord
  has_many :chats, dependent: :destroy
end
