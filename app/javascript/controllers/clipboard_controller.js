import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy(event) {
    event.preventDefault()

    const text = this.hasTextValue ? this.textValue : ""
    if (!text) return

    if (navigator.clipboard && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(text)
        return
      } catch (_error) {
        // Fall through to legacy fallback.
      }
    }

    this.copyWithExecCommand(text)
  }

  copyWithExecCommand(text) {
    const input = document.createElement("textarea")
    input.value = text
    input.setAttribute("readonly", "")
    input.style.position = "absolute"
    input.style.left = "-9999px"
    document.body.appendChild(input)
    input.select()
    document.execCommand("copy")
    input.remove()
  }
}
