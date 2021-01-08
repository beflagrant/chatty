class MessagesController < ApplicationController
  before_action :set_room
  before_action :set_message, only: [:edit, :update]

  def create
    @message = @room.messages.create(message_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @room }
    end
  end

  def update
    @message.update(message_params)
  end

  private

  def set_message
    @message = @room.messages.find_by_id(params[:id])
  end

  def set_room
    @room = Room.find(params[:room_id])
  end

  def message_params
    params.require(:message).permit(:comment).merge!(user: current_user)
  end
end
