import { Controller } from "stimulus"
import CableReady from 'cable_ready'

export default class extends Controller {
  static values = { id: String }

  connect () {
    this.channel = this.application.consumer.subscriptions.create(
      {
        channel: 'RoomChannel',
        id: this.idValue,
      },
      {
        received (data) { if (data.cableReady) CableReady.perform(data.operations) }
      }
    )
  }

  disconnect () {
    this.channel.unsubscribe()
  }
}
