Room.find_or_create_by(name: "Reactive Rails") do |r|
  r.description = "A place to discuss our escape from the shackles of React"
  r.color = "#CC0000"
end
