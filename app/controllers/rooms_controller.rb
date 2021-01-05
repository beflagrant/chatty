class RoomsController < ApplicationController
  before_action :require_user

  def show
    @room = Room.find_by(id: params[:id]) || Room.first
  end
end
