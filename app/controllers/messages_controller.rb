class MessagesController < ApplicationController
  before_action :set_room
  before_action :set_message, only: [:show, :edit, :update]

  def create
    @message = @room.messages.create(message_params)

    respond_to do |format|
      format.turbo_stream {
        # race condition here!
        # sleep 0.05
        Turbo::StreamsChannel.broadcast_replace_later_to @message.room,
          target: @message,
          partial: "messages/message",
          locals: { message: @message, current_user: current_user }
      }
      format.html { redirect_to @room }
    end
  end

  def show
    render @message
  end

  def update
    @message.update(message_params)
  end

  def edit
    render status: 403 unless @message.user == current_user
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
