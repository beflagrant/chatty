class MessagesController < ApplicationController
  before_action :set_room

  def create
    @message = @room.messages.create(message_params)

    redirect_to room_path(@room)
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def message_params
    params.require(:message).permit(:comment).merge!(user: current_user)
  end
end
