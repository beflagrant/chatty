module MessageHelper
  def message_color(message, locals)
    for_messenger?(message, locals) ? "bg-sky text-blue-900" : "bg-tan text-yellow-900"
  end

  def is_messenger?(message)
    message.user == current_user
  end

  def for_messenger?(message, locals)
    for_messenger = locals[:for_messenger]
    for_messenger.nil? ? is_messenger?(message) : for_messenger
  end
end
