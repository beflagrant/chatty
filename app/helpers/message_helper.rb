module MessageHelper
  def message_color(message)
    message.user == current_user ? "bg-sky text-blue-900" : "bg-tan text-yellow-900"
  end
end
