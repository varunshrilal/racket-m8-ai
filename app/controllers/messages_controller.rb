class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT = <<~PROMPT
    You are Racket M8, a helpful tennis match-making and court-planning assistant for Sydney.

    The app helps users:
    - find hitting partners and groups
    - coordinate times and courts
    - write friendly outreach messages
    - plan quick backups for last-minute cancellations

    Response rules:
    - Be concise. Default to 3-6 lines total.
    - Ask at most 2 clarifying questions, and only if required.
    - Do not provide full plans, checklists, or templates unless the user asks for them.
    - If the user message is vague (e.g. "hi"), reply with a short greeting + 1 question.
    - Prefer bullet points only when listing options.
    - Keep responses practical and specific.
    - Use Markdown lightly (avoid heavy headings unless requested).

    Follow-up behavior:
    - Preserve context from earlier messages in the chat.
    - On follow-up turns, update only what changed instead of repeating the full answer.
    - If the user asks for a message, return the message only (unless they ask for alternatives).
    - If the user asks for a backup option, return 1 clear backup option plus an optional short message if useful.
    - Avoid repetitive closers like "Let me know if you need more help" on every turn.

    Product scope:
    - You can help refine requests, create filters, draft outreach messages, and plan backups.
    - You do not have access to live player inventory or real-time court bookings in this demo.
    - If asked for live availability/results, say so briefly, then help the user turn the request into:
      1) a precise search/filter and
      2) a short outreach message.

    If mock inventory context is provided, use it to simulate a real app search result:
    - mention 2-4 matched player names from the mock list when relevant
    - mention 1-3 suitable courts from the mock list when relevant
    - do not invent "live" availability confirmations
    - frame results as likely matches / demo results, then help the user message or choose next steps

    Use an efficient, product-assistant tone.
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

      # Final sync in case streamed content and final response differ slightly
      @assistant_message.update!(content: @response.content.to_s)
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
  rescue Faraday::SSLError, Faraday::ConnectionFailed => e
    handle_llm_error("Network/SSL issue while contacting the AI provider. Please try again.", e)
  rescue => e
    handle_llm_error("Something went wrong while generating the reply.", e)
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
    [
      SYSTEM_PROMPT,
      topic_context,
      @topic.system_prompt,
      mock_inventory_context
    ].compact.join("\n\n")
  end

  def extracted_search_criteria
    # Parse only user messages so assistant replies don't pollute criteria extraction
    text = @chat.messages
                .where(role: "user")
                .order(:created_at)
                .pluck(:content)
                .compact
                .join("\n")
                .downcase

    suburb = extract_suburb(text)
    utr = extract_utr(text)
    level_label = extract_level_label(text)
    time_text = extract_time_text(text)
    players_needed = extract_players_needed(text)
    singles_only = text.include?("singles")

    {
      suburb: suburb,
      utr: utr,
      level_label: level_label,
      time_text: time_text,
      players_needed: players_needed,
      singles_only: singles_only
    }
  end

  def extract_suburb(text)
    known_suburbs = [
      "marrickville", "surry hills", "newtown", "enmore", "petersham",
      "dulwich hill", "stanmore", "camperdown", "ashfield", "leichhardt",
      "erskineville", "tempe", "sydenham", "moore park"
    ]

    match = known_suburbs.find { |s| text.include?(s) }
    match&.split&.map(&:capitalize)&.join(" ")
  end

  def extract_utr(text)
    # Matches: "utr 4", "UTR 4.0", "utr ~4", "utr around 4.5"
    match = text.match(/utr\s*(?:~|around)?\s*(\d+(?:\.\d+)?)/i)
    match ? match[1].to_f : nil
  end

  def extract_level_label(text)
    return "Beginner" if text.include?("beginner")
    return "Intermediate" if text.include?("intermediate")
    return "Advanced" if text.include?("advanced")

    nil
  end

  def extract_time_text(text)
    # Demo parser: "tuesday 8pm", "thu 7pm", "saturday 10:30am"
    match = text.match(
      /\b(mon|monday|tue|tues|tuesday|wed|wednesday|thu|thurs|thursday|fri|friday|sat|saturday|sun|sunday)\b.*?\b\d{1,2}(?::\d{2})?\s?(am|pm)\b/i
    )
    match ? match[0] : nil
  end

  def extract_players_needed(text)
    return 4 if text.include?("4 players") || text.include?("four players") || text.include?("doubles")
    return 2 if text.include?("2 people") || text.include?("two people")
    return 1 if text.include?("1 person") || text.include?("one person") || text.include?("hitting partner") || text.include?("singles")

    1
  end

  def enough_info_for_mock_search?(criteria)
    criteria[:suburb].present? &&
      (criteria[:utr].present? || criteria[:level_label].present?) &&
      criteria[:time_text].present?
  end

  def mock_inventory_context
    criteria = extracted_search_criteria
    return nil unless enough_info_for_mock_search?(criteria)

    result = RacketM8::MatchFinder.new(**criteria).call

    players_lines = result[:players].map do |p|
      "- #{p.name} (#{p.suburb}) · UTR #{p.utr} · #{p.level_label}"
    end

    courts_lines = result[:courts].map do |c|
      lights_text = c.lights ? "lights" : "no lights"
      "- #{c.name} (#{c.suburb}) · #{c.surface} · #{lights_text}"
    end

    notes_lines = result[:notes].map { |n| "- #{n}" }

    <<~CONTEXT
      DEMO MODE: Use the mock inventory below to simulate in-app search results.
      Be transparent this is demo/mock inventory, not live availability.
      Prefer referencing these names/courts (instead of generic placeholders) when helpful.

      Parsed search criteria:
      - Suburb: #{criteria[:suburb]}
      - UTR: #{criteria[:utr] || "not provided"}
      - Level: #{criteria[:level_label] || "not provided"}
      - Time: #{criteria[:time_text]}
      - Players needed: #{criteria[:players_needed]}
      - Singles only: #{criteria[:singles_only] ? "yes" : "no"}

      Matching players (mock):
      #{players_lines.any? ? players_lines.join("\n") : "- No mock players matched"}

      Suggested courts (mock):
      #{courts_lines.any? ? courts_lines.join("\n") : "- No mock courts matched"}

      Notes:
      #{notes_lines.any? ? notes_lines.join("\n") : "- No additional notes"}
    CONTEXT
  rescue NameError => e
    # In case MatchFinder isn't loaded yet, fail gracefully and continue without mock context
    Rails.logger.warn("mock_inventory_context skipped: #{e.class} - #{e.message}")
    nil
  end

  def handle_llm_error(user_message, error)
    Rails.logger.error("[MessagesController#create] #{error.class}: #{error.message}")

    if defined?(@assistant_message) && @assistant_message.present?
      @assistant_message.update_column(:content, user_message)
      broadcast_replace(@assistant_message)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "new_message_container",
          partial: "messages/form",
          locals: { chat: @chat, message: Message.new }
        ), status: :unprocessable_entity
      end
      format.html do
        redirect_to chat_path(@chat), alert: user_message
      end
    end
  end
end
