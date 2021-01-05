import ApplicationController from './application_controller'

/* This is the custom StimulusReflex controller for the Message Reflex.
 * Learn more at: https://docs.stimulusreflex.com
 */
export default class extends ApplicationController {
  /*
   * Regular Stimulus lifecycle methods
   * Learn more at: https://stimulusjs.org/reference/lifecycle-callbacks
   *
   * If you intend to use this controller as a regular stimulus controller as well,
   * make sure any Stimulus lifecycle methods overridden in ApplicationController call super.
   *
   * Important:
   * By default, StimulusReflex overrides the -connect- method so make sure you
   * call super if you intend to do anything else when this controller connects.
  */

  connect () {
    super.connect()
    // add your code here, if applicable
  }

  createSuccess(element, reflex, noop, reflexId) {
    element.querySelector("#new-comment").value = ''
  }

  keyup(event) {
    if(event.key === "Enter") { this.stimulate("Message#update", event.target) }
  }

}
