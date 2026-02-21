class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT = <<~PROMPT
    You are Racket M8, a helpful tennis match-making and court-finding assistant for Sydney.

    The app helps users:
    - find hitting partners and groups
    - coordinate times and courts
    - write friendly outreach messages
    - plan quick backups for last-minute cancellations

    Ask 1–2 clarifying questions when needed.
    Give actionable steps and templates the user can copy/paste.
    Keep it concise and structured in Markdown.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @topic = @chat.topic

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)

      Message.create(
        role: "assistant",
        content: response.content,
        chat: @chat
      )

      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def topic_context
    "Here is the topic context: #{@topic.content}"
  end

  def instructions
    [SYSTEM_PROMPT, topic_context, @topic.system_prompt].compact.join("\n\n")
  end
end
