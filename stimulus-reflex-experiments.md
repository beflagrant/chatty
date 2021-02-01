
# A Brief Study of Stimulus Reflex

This post continues our exploration of Reactive Rails tools with [StimulusReflex](https://docs.stimulusreflex.com/) and its underlying library [CableReady](https://cableready.stimulusreflex.com/). This is the third post in the series--if you need to catch up you can:

* [Getting to Reactive Rails]()
* [Reactive Rails from Bare Bones]()
* THIS THING
* HOTWIRED THING
* COMPARISION, CONTRAST, AND CONCLUSIONS

## First Impression

StimulusReflex had been making a splash in recent years and especially the last few months: GoRails created an [introductory video](https://gorails.com/episodes/stimulus-reflex-basics) in mid-April of 2020, and less than two weeks later the SR team released a [Twitter clone demo video](https://www.youtube.com/watch?v=F5hA79vKE_E&ab_channel=Hopsoft) of their own. Both videos promote using SR rather than heavy front-end frameworks. It would be eight months between these videos and the release of Hotwire.

The documentation and instrumentation for CR/SR seem quite mature and the development team is surprisingly accessible, friendly and generous on their [Discord channel](https://discord.gg/XveN625). This made integrating Stimulus Reflex straightforward, with a good human fallback if any hiccups happen.

At its core Stimulus Reflex is a set of patterns that provides some glue between Stimulus js and CableReady. Like Hotwire, CableReady provides a mechanism to update the DOM by sending mostly HTML and operations to the client; however, unlike Hotwire, CableReady solely depends on WebSockets[^fn1]  for communication while Hotwire only uses ActionCable for its Turbo Stream feature. It is also worth noting that StimulusReflex leans on a cool js project [morphdom](https://github.com/patrick-steele-idem/morphdom) for some of its more advanced manipulations of the DOM. 

Installation of StimulusReflex is pretty trivial following their docs but basically the steps were:

```sh
bundle add stimulus_reflex
bundle exec rails stimulus_reflex:install
```

With Stimulus Reflex installed, we can move on to integrating it with our bare bones application.

### Customizing Stimulus Reflex

The model we'll be using Stimulus Reflex to manage is the Message, so we first need to generate the reflex classes we'll build on:

```sh
rails g stimulus_reflex message
```

This will create `application_controller.js` and `message_controller.js` files in `app/javascript/controllers` for housing the SR-specific JavaScript and create `application_reflex.rb` and `message_reflex.rb` in `app/reflexes` for the SR-specific Ruby.

The first test in our app was to see how StimulusReflex did with broadcasting new messages to all client streams. We found that to be as trivial (and well-documented) in StimulusReflex as it was in Hotwire, so we decided to send a different payload to the message's creator than the one sent to other room subscribers.

This task is somewhat inobvious. Thankfully, we received some advice from the SR Discord channel to check out [The Logical Splitter Example](https://cableready.stimulusreflex.com/leveraging-stimulus#example-3-the-logical-splitter) in the docs. We were also advised to explore CableReady's extensible [Custom Operations](https://cableready.stimulusreflex.com/customization#custom-operations). Let's walk through how this played out.

First, we prepare our application layout. Inserting the user's id as a `meta` tag in the head of the layout will provide us with a reference we will use at later:

```erb
<%# in app/views/layouts/application.html.erb %>

<%= tag(:meta, name: :cable_ready_id, content: current_user&.id) %>
```

In our `MessageReflex` class we specify that when created via reflex, the message should broadcast two html snippets, one for the html that everyone in the room will see (`default_html`), one snippet that is rendered when the current user is the author of the message (`custom_html`):

```ruby
# in app/reflexes/message_reflex.rb
class MessageReflex < ApplicationReflex
  delegate :current_user, to: :connection
   
  def create
    message = room.messages.create(comment: element.value, user: current_user)

    message_broadcast(message, "##{dom_id(room)}", :insertAdjacentHtml)
    morph :nothing
  end
  
  def message_broadcast(message, selector, operation)
    cable_ready[RoomChannel].logical_split(
      selector: selector,
      operation: operation,
      default_html: render(message, locals: { for_messenger: false }),
      custom_html: {
        [current_user.id] => render(message, locals: { for_messenger: true }),
      }
    ).broadcast_to(room)
  end

  # ...

  def room
    @room ||= Room.find(element.dataset[:room_id])
  end
end
```

We can see that the channel the broadcast will use is `RoomChannel`, which we need to define. We're also providing a selector using `dom_id(room)` as the target html element of the broadcast.

The `StimulusReflex::Reflex class`, parent to `ApplicationReflex`, parent to our `MessageReflex` provides `element`, representing the html element that triggered the reflex. That element's dataset (all the `data-*` attributes of that element) includes a `:room_id`, allowing us to look up the specific Room we need.

As written, `RoomChannel` is boilerplate stuff. The `stream_for` indicates that for any given Room, a channel exists:

```ruby
# app/channels/room_channel.rb
class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_for Room.find(params[:id])
  end
end
```

We'll add the Room's `id` to a `div` tag in our view using `dom_id(@room)` so the channel knows which element to target as a container. We also include the room's `id` in `data-room-id-value=`, which makes it a part of the element's dataset:

```erb
<%# in app/views/rooms/show.html.erb %>
<div id="<%= dom_id(@room) %>" class="pt-4 mr-4 flex flex-col"
    data-controller="room"
    data-room-id-value=<%= @room.id %>>
  <%= render @room.messages %>
</div>
```

Specifically, within the channel RoomChannel, the broadcast targets the `logical_split` custom operation. We define that custom operation in our `application.js` file:

```javascript
// in app/javascript/packs/application.js
import CableReady from 'cable_ready'

// note the change in case convention!
// logicalSplit in js <-> logical_split in ruby
CableReady.DOMOperations['logicalSplit'] = detail => {
  const crId = document.querySelector('meta[name="cable_ready_id"]').content
  const custom = Object.entries(detail.customHtml).find(pair => pair[0].includes(crId)
  const html = custom ? custom[1] : detail.defaultHtml
  CableReady.DOMOperations[detail.operation]({
    element: detail.element,
    html: html,
  })
}
import "controllers"
```

Finally we set up the channel as outlined in the manual using a room controller:

```javascript
// in app/javascript/controllers/room_controller.js

import { Controller } from 'stimulus'
import CableReady from 'cable_ready'

export default class extends Controller {
  static values = { id: String }

  connect () {
    this.channel = this.application.consumer.subscriptions.create(
      {
        channel: 'RoomChannel',
        id: this.idValue,
      },
      {
        received (data) { if (data.cableReady) CableReady.perform(data.operations) }
      }
    )
  }

  disconnect () {
    this.channel.unsubscribe()
  }
}
```

Simple, right?

In many circumstances, there's no need to build all of this custom code. CableReady provides a diverse and comprehensive array of [operations](https://cableready.stimulusreflex.com/reference/operations) out of the box to manipulate the DOM and interact with the browser. We customized specifically because we wanted different visuals to highlight messages posted by the current user, which _doesn't_ happen out of the box. (Recall that in our Hotwire implementation, we did this using CSS.) This cost us ~50 lines of custom code and some boilerplate.

One neat feature of CableReady is that is can be used almost [anywhere](https://cableready.stimulusreflex.com/cableready-everywhere) in your Rails app. This is a fairly standard form for creating a message:

```ruby
<div class="bg-primary bg-opacity-90 w-full p-4">
  <%= form_with model: [@room, Message.new] do |f| %>
    <div class="flex">
      <%= f.text_field(
        :comment,
        autocomplete: "off",
        placeholder: "Start a conversation",
        class: "rounded-full border p-3 flex-1 text-sm outline-none") %>
     </div>
   <% end %>
</div>
```

We can use `CableReady::Broadcaster` (which extends `ActiveSupport::Concern`) in our Message controller to broadcast a newly-created message:

```ruby
# app/controllers/message_controller.rb
class MessageController < ApplicationController
  include CableReady::Broadcaster
  def create
    @message = @room.messages.create(message_params)

    cable_ready[RoomChannel].logical_split(
      selector: dom_id(@room),
      operation: :insertAdjacentHtml,
      default_html: render_to_string(@message, locals: { for_messenger: false }),
      custom_html: {
      [@message.user_id] => render_to_string(@message, locals: { for_messenger: true }),
    }
  )
    cable_ready.broadcast_to(@room)
  end
end
```

We could have used an `after_create` hook in the Message model for the same effect.

In exploring the `reflex` part of StimulusReflex a little more thoroughly, we decided to move the logic into a Reflex. This way we won't need a `<form>` tag at all. To do that, we add a `reflex:` key to our text field's data attribute:

```ruby
<div class="bg-primary bg-opacity-90 w-full p-4" data-controller="message">
  <div class="flex">
    <%= text_field_tag(:comment, "",
      autocomplete: "off",
      placeholder: "Start a conversation",
      class: "rounded-full border p-3 flex-1 text-sm outline-none",
      data: { reflex: "change->Message#create", room_id: @room.id }) %>
  </div>
</div>
```

Stimulus Reflex inherits the quirky syntax (`change->Message#create`) from the Stimulus framework, adding in the `reflex:` innovation. If it seems odd at first, it may grow on you. The `change` sets the event on which to act, `Message` refers to the `MessageReflex` class we defined earlier, and `#create` marks the method to call on that reflex. By defining a reflex on the element, we can take advantage of the [client side callbacks](https://docs.stimulusreflex.com/lifecycle#client-side-reflex-callbacks) that StimulusReflex provides for all reflexes that have a corresponding (JavaScript) `Controller` in `app/javascript/controllers`. It would be nice to clear the input after creating the message, so we add the following:

```javascript
// in app/javascript/controllers/message_controller.js
   createSuccess(element) {
     element.value = ''
   }
```

Looking back at the `create` method of `MessageReflex` above you will note the call to `morph :nothing`. In that reflex we are overriding the default behavior and using CableReady directly.

As we tackle editing behavior, we can showcase the default morph behavior or a reflex. Let's start with our message partial. While the partial is very busy, it doesn't deviate too far from what we'd expect the partial to look like in a typical Rails application:

```erb
<%# app/views/messages/_message.html.erb %>
<div class="<%= message_color(message, local_assigns) %>
            rounded-2xl px-4 py-2 mb-2 text-s w-fit"
     id="<%= dom_id(message) %>"
     data-reflex-root="#<%= dom_id(message) %>"
     data-controller="message">
  <div class="flex flex-row items-center">
    <div>
      <span class="inline-block font-bold text-sm"><%= message.user.handle %></span>
      <span class="inline-block ml-1 text-xs"><%= message.created_at.strftime("%l:%M%P") %></span>
      <% if for_messenger?(message, local_assigns) %>
        <% if @editing %>
          <span data-reflex="click->Message#cancel" data-id=<%= message.id %> class="inline-block text-xs ml-2 hover:underline">
            Cancel
          </span>
        <% else %>
          <span data-reflex="click->Message#edit" data-id=<%= message.id %> class="inline-block text-xs ml-2 hover:underline">
            Edit
          </span>
        <% end %>
      <% end %>
    </div>
  </div>
  <% if @editing %>
    <%= text_area_tag :comment, message.comment,
      class: "block min-w-min w-72 md:w-96 m-2 h-32 p-2 text-black",
      data: {
        reflex: "change->Message#update",
        action: "keyup->message#keyup",
        id: message.id,
        room_id: message.room_id } %>
  <% else %>
    <div class="text-black w-full">
      <%= message.comment %>
    </div>
  <% end %>
</div>
```

We are building this as an exploration, otherwise we might not mix up quite as much logic into our partial. We can inform the partial whether or not the viewer is the messenger--the message sender--or not with the following helper:

```ruby
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
```

As a result, viewers will be able to differentiate between message they've sent and those sent by others regardless of whether or not they're receiving messages as a result of a page refresh or updates from the channel they're subscribed to.

We also now can see our remaining edit/update reflexes setup in the view partial which respectively call the falling actions in our MessageReflex: 

```ruby
# in app/reflexes/MessageReflex
  def edit
    @message = Message.find(element.dataset[:id])
    @editing = true
  end

  def update
    message = Message.find(element.dataset[:id])
    message.update(comment: element[:value])

    message_broadcast(message, "##{dom_id(message)}", :outerHtml)
    morph :nothing
  end
```

Looks strangely familiar; almost like a controller? When the `edit` button is clicked, the triggered reflex renders the partial and sends the update through the channel. On the client side, the default StimulusReflex controller (JS) uses `morphdom` to efficiently diff and apply the new/updated DOM elements. As a result, users see the kind of snappy edit-in-place field they've come to expect in modern web applications. Most of the heavy lifting here is done by StimulusReflex itself, without our intervention. This may be the closest we came to the kind of use case StimulusReflex is designed to simplify.

The `update` method also makes use of `message_broadcast`, this time using the CableReady `:outerHtml` directive. This matches the message using the `dom_id` and replaces the content for all subscribers to the room channel. We add some final polish by 'stimulating' the `Message#update` reflex when the user hits the 'Enter' key. We add this to the JS controller:

```javascript
  // in app/javascript/controllers/message_controller.js
  keyup(event) {
    if(event.key === "Enter") { this.stimulate("Message#update", event.target) }
  }
```

## Conclusion

In the first post of this series, we tried to provide some background on web application technologies, for context on why 'Reactive Rails' is having a moment. (If you missed it, you can [read it here](#).

In this brief study, we've exercised some of the core and custom capabilities of CableReady and StimulusReflex, at least enough for the team at Flagrant to form some early opinions. We have not remotely plumbed the depths of features and capability these libraries can provide, but it's a thorough start.

In the next post in this series, we'll give Hotwire the same treatment. Finally, we'll compare and contrast the two, hopefully providing some useful information to other developers looking for a good fit.

## Footnotes

[fn1]: Stimulus Reflex uses ActionCable by default. [Integration with AnyCable](https://docs.stimulusreflex.com/deployment#anycable) is possible as well.