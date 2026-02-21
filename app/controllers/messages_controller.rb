class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT = <<~PROMPT
    You are Racket M8, a helpful tennis match-making and court-finding assistant for Sydney.

    The app helps users:
    - find hitting partners and groups
    - coordinate times and courts
    - write friendly outreach messages
    - plan quick backups for last-minute cancellations

    Response rules:
    - Be concise. Default to 4-8 lines total.
    - Ask at most 2 clarifying questions, and only if required.
    - Do not provide full plans, checklists, or templates unless the user asks for them.
    - If the user message is vague (e.g. "hi"), reply with a short greeting + 1 question.
    - Prefer bullet points only when listing options.
    - Avoid repeating previously given advice unless the user asks for a recap.
    - Keep responses practical and specific.

    Use Markdown lightly.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @topic = @chat.topic

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history

      response = @ruby_llm_chat
        .with_instructions(instructions)
        .ask(@message.content)

      @chat.messages.create!(
        role: "assistant",
        content: response.content
      )

      @chat.generate_title_from_first_message if @chat.respond_to?(:generate_title_from_first_message)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "new_message_container",
            partial: "messages/form",
            locals: { chat: @chat, message: @message }
          ), status: :unprocessable_entity
        end
        format.html { render "chats/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def build_conversation_history
    @chat.messages.order(:created_at)[0...-1].each do |message|
      @ruby_llm_chat.add_message(
        role: message.role,
        content: message.content
      )
    end
  end

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
