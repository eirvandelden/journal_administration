import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quickFilter", "startDate", "endDate"]

  applyQuickFilter() {
    const filter = this.quickFilterTarget.value
    if (!filter) return

    const today = new Date()
    let startDate, endDate

    switch (filter) {
      case "current_month":
        startDate = new Date(today.getFullYear(), today.getMonth(), 1)
        endDate = new Date(today.getFullYear(), today.getMonth() + 1, 0)
        break
      case "last_month":
        startDate = new Date(today.getFullYear(), today.getMonth() - 1, 1)
        endDate = new Date(today.getFullYear(), today.getMonth(), 0)
        break
      case "three_months":
        startDate = new Date(today.getFullYear(), today.getMonth() - 3, 1)
        endDate = new Date(today.getFullYear(), today.getMonth(), 0)
        break
      case "current_year":
        startDate = new Date(today.getFullYear(), 0, 1)
        endDate = new Date(today.getFullYear(), 11, 31)
        break
      case "last_year":
        startDate = new Date(today.getFullYear() - 1, 0, 1)
        endDate = new Date(today.getFullYear() - 1, 11, 31)
        break
    }

    if (startDate && endDate) {
      this.startDateTarget.value = this.formatDate(startDate)
      this.endDateTarget.value = this.formatDate(endDate)
      this.element.requestSubmit()
    }
  }

  formatDate(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")

    return `${year}-${month}-${day}`
  }
}
