class Message < ApplicationRecord
  belongs_to :chat

  MAX_USER_MESSAGES = 10

  validates :role, presence: true
validates :content, presence: true, if: -> { role == "user" }
  validate :user_message_limit, if: -> { role == "user" }

  after_create_commit :broadcast_append_to_chat

  private

  def user_message_limit
    return unless chat

    if chat.messages.where(role: "user").count >= MAX_USER_MESSAGES
      errors.add(:content, "You can only send #{MAX_USER_MESSAGES} messages per chat.")
    end
  end

  def broadcast_append_to_chat
    broadcast_append_to(
      chat,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end
end
