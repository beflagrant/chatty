module MessageHelper
  def message_color(message)
    message.user == current_user ? "bg-sky text-blue-900 self-end align-right" : "bg-purple text-indigo-900"
  end
end
