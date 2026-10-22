import { Controller } from "@hotwired/stimulus"

// Submits the form this controller sits on, e.g. when a quick filter select changes.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
