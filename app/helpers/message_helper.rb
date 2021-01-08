module MessageHelper
  def message_color(message)
    (current_user.nil? || message.user == current_user) ? "bg-sky text-blue-900" : "bg-tan text-yellow-900"
  end

  def converse(message)
    (current_user.nil? || message.user == current_user) ? "flex-row-reverse w-full" : ""
  end
end
