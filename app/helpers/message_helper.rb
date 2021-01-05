module MessageHelper
  def message_styles(message, locals)
    if for_messenger?(message, locals)
      "bg-sky text-blue-900 self-end align-right"
    else
      "bg-purple text-indigo-900"
    end
  end

  def is_messenger?(message)
    message.user == current_user
  end

  def for_messenger?(message, locals)
    for_messenger = locals[:for_messenger]
    for_messenger.nil? ? is_messenger?(message) : for_messenger
  end
end
