import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "input", "form"]

  connect() {
    this.handleKeydownBound = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydownBound)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydownBound)
    clearTimeout(this.debounceTimer)
  }

  open() {
    this.dialogTarget.showModal()
    this.inputTarget.focus()
  }

  close() {
    this.dialogTarget.close()
  }

  handleBackdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  debounceSearch() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300)
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.open()
    }
  }
}
