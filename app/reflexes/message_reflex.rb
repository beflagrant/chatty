# frozen_string_literal: true

class MessageReflex < ApplicationReflex
  delegate :current_user, to: :connection

  def create
    message = room.messages.create(comment: element.value, user: current_user)

    message_broadcast(message, dom_id(room), :insertAdjacentHtml)
    morph :nothing
  end

  def edit
    @message = Message.find(element.dataset[:id])
    @editing = true
  end

  def update
    message = Message.find(element.dataset[:id])
    message.update(comment: element[:value])

    message_broadcast(message, dom_id(message), :outerHtml)
    morph :nothing
  end

  def cancel
    @editing = false
  end

  private

  def message_broadcast(message, selector, operation)
    cable_ready[RoomChannel].logical_split(
      selector: selector,
      operation: operation,
      default_html: render(message, locals: { for_messenger: false }),
      custom_html: {
        [current_user.id] => render(message, locals: { for_messenger: true }),
      }
    ).broadcast_to(room)
  end

  def room
    @room ||= Room.find(element.dataset[:room_id])
  end
end
