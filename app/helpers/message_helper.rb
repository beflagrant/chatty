module MessageHelper
  def message_color(message, for_messenger)
    is_messenger = (for_messenger.nil? ? is_messenger?(message) : for_messenger)
    is_messenger ? "bg-sky text-blue-900" : "bg-tan text-yellow-900"
  end

  def is_messenger?(message)
    message.user == current_user
  end
end
