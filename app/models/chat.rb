class Chat < ApplicationRecord
  belongs_to :topic
  belongs_to :user
  has_many :messages, dependent: :destroy

  def generate_title_from_first_message
    return if title.present? && title != "Untitled"

    first_user_message = messages.where(role: "user").order(:created_at).first
    return if first_user_message.blank? || first_user_message.content.blank?

    generated_title = first_user_message.content.strip
    generated_title = generated_title.gsub(/\s+/, " ")
    generated_title = generated_title.truncate(60)

    update(title: generated_title)
  end
end
