// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

Turbo.config.drive.confirmationMethod = (message, element) => {
  return new Promise((resolve) => {
    const dialog = document.getElementById("confirm-dialog")
    const messageEl = document.getElementById("confirm-dialog-message")
    const acceptBtn = document.getElementById("confirm-dialog-accept")
    const cancelBtn = document.getElementById("confirm-dialog-cancel")

    messageEl.textContent = message
    acceptBtn.textContent = element.dataset.confirmVerb || acceptBtn.dataset.defaultLabel

    let confirmed = false

    const onAccept = () => { confirmed = true; dialog.close() }
    const onCancel = () => { dialog.close() }

    acceptBtn.addEventListener("click", onAccept, { once: true })
    cancelBtn.addEventListener("click", onCancel, { once: true })
    dialog.addEventListener("close", () => {
      acceptBtn.removeEventListener("click", onAccept)
      cancelBtn.removeEventListener("click", onCancel)
      resolve(confirmed)
    }, { once: true })

    dialog.showModal()
  })
}
