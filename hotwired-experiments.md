
# A Brief Study of Hotwire

We continue our exploration of Reactive Rails tools with [Hotwire](https://hotwire.dev/). This is the fourth post in the series--if you need to catch up, you can:

* [Getting to Reactive Rails]()
* [Reactive Rails from Bare Bones]()
* [A Brief Study of Stimulus Reflex]()

In the post follosing this, we'll look at both of our chosen contenders. For now, we'll focus on Hotwire by its lonesome.

Hotwire is an umbrella project that melds [Turbo](https://turbo.hotwire.dev/) and [Stimulus](https://stimulus.hotwire.dev). Turbo supersedes [Turbolinks](https://github.com/turbolinks/turbolinks), a long-time Rails standby for accelerating web view rendered on the server side. Turbo continues this feature set while adding _Turbo Frames_ and _Turbo Streams_. Turbo Frames allow you to create a component with independent functionality, somewhat similar to an `iframe` in concept. Turbo Streams provide a communication layer between your service and (among other things) the Turbo Frames using WebSockets or server-sent events (SSE).

Let's dive in!

## First Impression

Our approach to Hotwire was similar to our approach to Stimulus Reflex: videos, documentation, then extend our bare chat application with our desired functionality. With Hotwire, we dug into the source a little bit more. This wasn't unexpected--while Hotwire includes Turbo as an extension to Turbolinks and Stimulus is no spring chicken, combining them together as Hotwire is a new approach and not much in the way of thorough guidance was available while we were experimenting.

The pedigree here is non-trivial. Turbolinks was an early entry attempting to get the speed of the single-page application (SPA) without converting your entire front-end to JS. Like the early Rails 'unobtrusive JavaScript' approach, Turbolinks could integrate almost transparently. The Turbolinks approach is nearly a decade old at this point and predates React--though not AngularJS. Turbolinks 5 released with Rails 5, beginning a transition from CoffeeScript to TypeScript. Turbo completes this transition while adding new functionality in the same vein.

Stimulus has been under development for 5 years, long enough for the Stimulus Reflex framework to have been built atop it and matured quite a bit. It bills itself as 'a JavaScript framework with modest ambitions'. Stimulus works via (JS) Controllers, declared in a `data-action=` attribute on an HTML element, using the quirky (`event->Controller#method`) syntax we saw briefly in our Stimulus Reflex experiment.

Because the `data-actions` can be added to any element, it can seamlessly be added to a `turbo-frame` element. If the functionality of a Turbo Frame isn't quite enough, you can use Stimulus to augment--at least, that's the thinking.

The components of the Hotwired umbrella are collected for installation in Rails under the [hotwire-rails](https://github.com/hotwired/hotwire-rails) gem. Installing using the instructions:

```sh
bundle add hotwire-rails
bundle add redis # surprise!
bin/bundle install
bin/rails hotwire:install
```

Redis? Perhaps that shouldn't have been surprising, and the error messages alerting to its absence were clear.

With Hotwire installed, we set about integrating it into our chat servce.

QUESTIONS TO ANSWER:

How difficult to add to a new project?
How easy to integrate into an existing project? (Given webpacker vs sprockets.)
What dependencies does it bring to the party?
Special concern: for an existing API driven project w/ a React front end, how
‘expensive’ is it to convert?
What is the learning curve of each project? How good is the documentation?
How fast can one get to a minimal/prototypical implementation?

## Integrating Hotwire

To make this a little easier on your eyes, we'll remove the styling from the inline code here. If you want _all_ the deets, you can have a look at the [source code](https://github.com/beflagrant/chatty).

Recall our required features:

1) Any user must be able to easily differentiate their own messages in the view
2) Any user must be able to edit only their own messages
3) Every user sees updates in real time

Naturally, we started with the third feature: updating in real time. This proved remarkably simple. We added the Turbo- and Stimulus-specific tags to the head of our layout:

```erb
  <head>
    <!-- in app/views/layouts/application.html.erb -->
    <%= turbo_include_tags %>
    <%= stimulus_include_tags %>
    <!-- ... -->
  </head>
```

Recall that we have three models:

* User - a handle representing a participating user
* Room - a chat room or channel that contains messages
* Message - a message from a User to a Room

For any given room, we display a list of messages. To add the real-time aspect, we need a source of updates, and we add that as a Turbo Stream, using `turbo_stream_from(@room)`:

```erb
<!-- in app/views/rooms/show.html.erb -->
<!-- next line added: -->
  <%= turbo_stream_from @room %>
  <div>
    <%= @room.name %>:
    <%= @room.description %>
  </div>
  <div id="messages">
    <%= render @room.messages %>
  </div>
  <%= form_with model: [@room, Message.new] do |f| %>
    <div>
      <%= f.text_field(
        :comment,
        autocomplete: "off",
        placeholder: "Start a conversation") %>
    </div>
  <% end %>
```

We need to tell the model that when there's a new message, send it to the appropriate Turbo Stream. We do that with `broadcasts_to` in the model's definition:

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :room
  belongs_to :user
  broadcasts_to :room      # added
end
```

That's it. When a message is created, it broadcasts to the associated room. Turbo infers the proper place to put a new message by looking for an element with an id of `messages`, and do the right thing when a message is created.

Changes and deletion require a little more wiring, but not much. For this, we simply let Turbo know where a message lives by wrapping the message's partial in a `turbo-frame`:

```erb
<!-- in app/views/messages/_message.html.erb -->
<%= turbo_frame_tag dom_id(message) %>
  <div id="<%= dom_id(message) %>">
    <div>
        <span>
          <%= link_to "edit", edit_room_message_path(message.room, message) %>
        </span>
        <span><%= message.user.handle %></span>
        <span><%= message.created_at.strftime("%l:%M%P") %></span>
    </div>
    <div>
      <%= message.comment %>
    </div>
  </div>
<% end %>
```

Done! Now changes to messages will find the correct message, because we've used `dom_id(message)` to identify to the message to Turbo. But where is the user supposed to edit a message? Ah yes, the edit button. We would then expect that the 



Next, we tell the controller that if the message is being updated from a `turbo-frame`, send it out on the associated stream:



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

If this syntax (`change->Message#create`) seems odd at first, it may grow on you. The `change` sets the event on which to act, `Message` refers to the `MessageReflex` class we defined earlier, and `#create` marks the method to call on that reflex. By defining a reflex on the element, we can take advantage of the [client side callbacks](https://docs.stimulusreflex.com/lifecycle#client-side-reflex-callbacks) that StimulusReflex provides for all reflexes that have a corresponding (JavaScript) `Controller` in `app/javascript/controllers`. It would be nice to clear the input after creating the message, so we add the following:

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

As a result, viewers will be able to differentiate between message they've sent and those sent by others regardless of whether or not they're receiving messages as a result of a page refresh or missives from the channel they're subscribed to.

We also now can see our remaining edit/update reflexes setup in the view partial which respectively call the falling actions in our MessageReflex: 

```ruby
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

Looks strangely familiar; almost like a controller you might say? The edit reflex is using a page morph which will use the default StimulusReflex controller to do a full morph of the current user's html using the efficient diffing logic of morphdom js with lightening speed and no flashes. Our comment is immediately transformed into a text field for in place editing that users have come to expect from modern web applications. This is the closest we got to the traditional use of StimulusReflex in which a user page interaction creates an immediate effect on the page; however, notice that all our instructions are coming the server side!

You will also notice the reuse of the message_broadcast method in the MessageReflex#update action, this time using the CableReady outerHtml method which will match and replace the message by dom_id for all subscribers to the room channel. And a final little gesture of Stimulus, this time a data-action for the keyup event which calls this action in our js controller: 

```javascript
  keyup(event) {
    if(event.key === "Enter") { this.stimulate("Message#update", event.target) }
  }
```

As you can see reflexes can also be called from the client side so that hitting enter triggers an update from the message comment edit text area box. 

With this we have nowhere near exhausted the capabilities of CableReady and StimulusReflex but just with these few features given a pretty impressive demonstration of the potential nonetheless.

## Features, Compared

This starts the conversation on what is good for what type of application, and
where the trade-offs live.
Stimulus (Common)
Hotwire / Turbo
Stimulus Reflex

GOTCHA: session data doesn't go over the wire

GOTCHA: only one version of the partial is broadcast -- the user display
handling needs to be alive on the client (browser)

NOTE: multi-user applications become more difficult in this case, but the
competing solution was a cable-ready solution with multiple broadcast branches

## Active Development / Support

Current issues, lifetime contributions, active community, backing and likely
adoption based on current understanding.
Experience Report / Observations
Describe our use case, and why we were having this discussion with some
particulars, our goals from a user experience and implementation point of view.

Describe what we chose and why we chose it for this use case, with a YMMV.

## Conclusions

Summary of comparisons, recommendations for use cases.

## References

- Hotwire repo: [https://github.com/hotwired/hotwire-rails](https://github.com/hotwired/hotwire-rails)
- Hotwire tutorial on GoRails: [https://gorails.com/episodes/hotwire-rails](https://gorails.com/episodes/hotwire-rails)
