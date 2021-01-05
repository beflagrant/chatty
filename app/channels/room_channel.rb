class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_for Room.find(params[:id])
  end
end
