import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-scroll"
export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.scrollToBottom()
    this.boundScroll = this.scrollToBottom.bind(this)
    document.addEventListener("turbo:render", this.boundScroll)
    document.addEventListener("turbo:submit-end", this.boundScroll)
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.boundScroll)
    document.removeEventListener("turbo:submit-end", this.boundScroll)
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
