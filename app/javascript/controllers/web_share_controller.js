import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    title: String,
    text: String
  }

  async share(event) {
    event.preventDefault()

    if (!this.hasUrlValue) return

    if (navigator.share) {
      try {
        await navigator.share({
          url: this.urlValue,
          title: this.hasTitleValue ? this.titleValue : undefined,
          text: this.hasTextValue ? this.textValue : undefined
        })
        return
      } catch (error) {
        if (error.name === "AbortError") return
      }
    }

    this.fallbackShare()
  }

  fallbackShare() {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(this.urlValue).catch(() => {
        window.open(this.urlValue, "_blank", "noopener,noreferrer")
      })
      return
    }

    window.open(this.urlValue, "_blank", "noopener,noreferrer")
  }
}
