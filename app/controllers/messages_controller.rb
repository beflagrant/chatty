class MessagesController < ApplicationController
  before_action :set_room

  def create
    @message = @room.messages.create(message_params)

    cable_ready[RoomChannel].logical_split(
      selector: dom_id(@room),
      operation: :insertAdjacentHtml,
      default_html: render_to_string(@message, locals: { for_messenger: false }),
      custom_html: {
        [@message.user_id] => render_to_string(@message, locals: { for_messenger: true }),
      }
    )
    cable_ready.broadcast_to(@room)
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def message_params
    params.require(:message).permit(:comment).merge!(user: current_user)
  end
end
