import { Controller } from "@hotwired/stimulus"

// Manages dynamic addition and removal of budget category rows in the budget form.
export default class extends Controller {
  static targets = ["container", "template", "row", "destroy_field"]

  add() {
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    const row = event.target.closest("[data-budget-categories-target='row']")

    const destroyField = row.querySelector("[data-budget-categories-target='destroy_field']")

    if (destroyField) {
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
