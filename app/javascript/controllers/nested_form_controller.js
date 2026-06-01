import { Controller } from "@hotwired/stimulus"

// Adds and removes rows in a nested form — used for the site links on the
// settings page. New rows are cloned from a <template> whose child index is a
// placeholder ("NEW_RECORD") that we swap for a unique value so each row's
// fields submit under their own links_attributes key.
export default class extends Controller {
  static targets = ["rows", "template"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString())
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-target='row']")
    if (!row) return

    // A persisted link renders a hidden id field; mark it for destruction and
    // hide it so the server deletes it on save. A brand-new (unsaved) row has no
    // id, so we can just drop it from the DOM.
    const idField = row.querySelector("input[name*='[id]']")
    if (idField) {
      row.querySelector("input[name*='[_destroy]']").value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
