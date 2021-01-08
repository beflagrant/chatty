import { Controller } from "stimulus"

export default class extends Controller {
  reset() {
    console.log("YLLO")
    this.element.reset()
  }
}
