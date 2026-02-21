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
      @assistant_message = @chat.messages.create!(
        role: "assistant",
        content: ""
      )

      send_question

      @assistant_message.update!(content: @response.content)
      broadcast_replace(@assistant_message)

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

  def send_question(model: "gpt-4o-mini", with: {})
    @ruby_llm_chat = RubyLLM.chat(model: model)
    build_conversation_history
    @ruby_llm_chat.with_instructions(instructions)

    @response = @ruby_llm_chat.ask(@message.content, with: with) do |chunk|
      next if chunk.content.blank?

      @assistant_message.content ||= ""
      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  end

  def broadcast_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: helpers.dom_id(message),
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def build_conversation_history
    @chat.messages.order(:created_at).each do |message|
      next if message.content.blank?

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
