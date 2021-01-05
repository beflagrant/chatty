module MessageHelper
  def message_color(message)
    message.user == current_user ? "bg-sky" : "bg-tan"
  end
end
