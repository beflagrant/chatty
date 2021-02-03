
# A Brief Study of Hotwire

We continue our exploration of Reactive Rails tools with [Hotwire](https://hotwire.dev/). This is the fourth post in the series--if you need to catch up, you can:

* [Getting to Reactive Rails]()
* [Reactive Rails from Bare Bones]()
* [A Brief Study of Stimulus Reflex]()

In the post following this, we'll look at both of our chosen contenders. For now, we'll focus on Hotwire by its lonesome.

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

To make this a little easier on your eyes, we'll remove the styling from the inline code here. If you want _all_ the deets, you can have a look at the [source code](https://github.com/beflagrant/chatty/tree/hotwire).

Recall our required features:

1) Any user must be able to easily differentiate their own messages in the view
2) Any user must be able to edit only their own messages
3) Every user sees updates in real time

Naturally, we started with the third feature: updating in real time.

### Updates in Real Time

This feature proved remarkably simple. We added the Turbo- and Stimulus-specific tags to the head of our layout:

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

That's it. When a message is created, it broadcasts to the associated room. Turbo infers the proper place to put a new message by looking for an element with an id of `messages`, and do the right thing when a message is created. It looks for the message partial in the usual places, and renders it if it's found.

Users can create the message using the text-box at the bottom of the page. As it currently stands, when the user submits the form the messages controller creates the new message and redirects to the show page for the room itself, triggering a full page render. The clever bit here is that Turbo intercepts the outgoing request and response, and replaces the page's `body` with the response from the `POST`, so it feels like a single page app.

Still, we can imagine a long-running chat where the render becomes quite large, and sending all that data back across the wire--even a very clever wire--gets somewhat onerous. Instead, we can tell the controller that if the `POST` comes in through Turbo, it should post the response to the stream instead of redirecting to a full page render. This next bit is tricky, so bear with us:

```ruby
# in app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def create
    @message = @room.messages.create(message_params)

    respond_to do |format|
      format.turbo_stream  # this line added
      format.html { redirect_to @room }
    end
  end
```

We lied about it being tricky. What's impressive here is that _in either case_, whether you've added `format.turbo_stream` or not, a full-page render isn't triggered. If you _do_ have our magic line added, we only render the message's partial and send it out over the room's stream (because of our `broadcasts_to` in the Message model, above) where it will be added to the element with an `id` of `messages`.

Allowing for a feedback over the `format.turbo_stream` can be an important step. If the full-page render were large and the room had many participants, this would generate unnecessary amounts of traffic. By feeding just the partial back over the stream, we can be much more efficient. Making this change for our toy application yielded a response of 1.1KB, vs the 20KB of a relatively vacant room.

### Turbo Stream Messages

Let's divert here for a moment. Earlier, we noted that Turbo uses WebSockets to transmit updates. What does that mean? What does that message look like?

In the case of a new message, it looks like this:

```json
{
  "identifier": {
    "channel":"Turbo::StreamsChannel",
    "signed_stream_name":"some-long-identifier"
  },
  "message":"PLACEHOLDER"
}
```

The `PLACEHOLDER` content is below--extracted and unescaped so we could have nice syntax:

```html
<turbo-stream action="append" target="messages">
  <template>
    <turbo-frame id="message_83">
      <div id="message_83">
        <span>
          <a href="/rooms/1/messages/83/edit">edit</a> 
        </span>
        <span>bvandg</span>
        <span>10:46pm</span>
      </div>
      <div>
        this is the message body / comment / whatever
      </div>
    </turbo-frame>
  </template>
</turbo-stream>
```

When that message comes across the WebSocket, Turbo finds the action `append` and the target `messages`, then appends the content of the `template` to the target. Other available actions are `prepend`, `replace`, `update`, and `remove`. With that, we can return to the other features we want to implement in our experiment.

### Editing Messages in Place

The next feature: users should be able to edit their own messages. First, we'll tackle a naïve implementation, and later we'll explore some of the difficulties.

Simple changes and deletion require a little more wiring, but not much. For this, we simply let Turbo know where a message lives by wrapping the message's partial in a `turbo-frame`:

```erb
<!-- in app/views/messages/_message.html.erb -->
<%= turbo_frame_tag dom_id(message) %>
  <div>
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

Done! Now changes to messages will find the correct message, because we've used `dom_id(message)` to identify to the message to Turbo. But where is the user supposed to edit a message? Ah, the edit link.

We would naturally expect the edit link to send us off to a page for editing a message, given we've provided no facility for our `turbo-frame` to take over. When we click the link, that doesn't happen at all. This can be a bit surprising and mysterious. In fact, the outgoing request is being intercepted, and the HTML for the form being returned as expected _but_ without any guidance as to where the resulting HTML should be displayed on the page, Turbo drops it into the ether.

Because we have a `turbo-frame` on the page with the dom_id() of the message, we can add a `turbo-frame` element to our edit form and provide the guidance needed. In this case, we just add a wrapper around the form, and give it the message's dom id:

```erb
<!-- in app/views/messages/edit.html.erb -->
<%= turbo_frame_tag dom_id(@message) do %>
  <div>
    <span><%= @message.user.handle %></span>
    <span>
      <%= @message.created_at.strftime('%l:%M') %>
      <%= link_to "cancel", room_message_path(@message.room, @message) %>
    </span>
    <div>
      <%= form_with model: [@message.room, @message] do  |f| %>
        <div>
          <%= f.text_field(
            :comment,
            autocomplete: "off" ) %>
        </div>
      <% end %>
    </div>
  </div>
<% end %>
```

Done. Now clicking 'edit' will replace the message with the populated message form, as we would expect. Incidentally, this doesn't affect routing directly. Typing `/rooms/1/messages/84/edit` (for example) would bring up the same form for editing the message with `id=84`. You can also put whatever other HTML you need to if you're doing a full-page render of the edit form, but only the `turbo-frame` content with the appropriate `dom_id()` will be merged into the page.

We've now finished our simplistic edit/update workflow and completed the corresponding feature, but we have a problem.

### Controlling Access

While users can edit their own messages. Users can ALSO edit other users' messages. We can make this implementation less naïve by adding a simple check in our `edit` method on the controller:

```ruby
  # in app/controllers/messages_controller.rb
  def edit
    render status: 403 unless @message.user == current_user
  end
```

We finish up with a corresponding check in our message partial to elide the link if we're not the user who created the message:

```erb
        <!-- in app/views/messages/_message.html.erb -->
        <% if current_user == message.user %>
          <span>
            <%= link_to "edit", edit_room_message_path(message.room, message) %>
          </span>
        <% end %>
```

You'll also note that there's a 'cancel' link, which links to the message's `show` route. Since our `_message` partial already includes the `turbo-frame`, it will replace the form with the message partial without us having to take any extra steps.

For the curious, we're verifying that the responses come back as expected and are interpreted correctly by monitoring the network tab in the inspector, watching for responses to requests initiated by `application.js` and messages passed via the WebSocket. The WebSocket shows up as `cable` in Firefox's inspector.

### Did We Break Anything?

So, walking back through to verify our functionality all still works, we see an interesting thing. When we enter a new message using the text area at the bottom of the screen, our message appears, but the `edit` link is missing!

What happened? Looking through the network tab on the inspector, we can see the that the result of the `POST` to `/rooms/:id/messages` is a status 204: No Content. So where did the message that popped up come from? It was sent via the WebSocket, because our Message model broadcasts it. However, the Message and WebSocket don't know anything about the current user, so it broadcasts the rendered template without the 'edit' link.

We can fix this by sending a rendering that replaces the current `turbo-frame` but includes the 'edit' link. We only want to send this to the User who created the message, and only to the Room the message is in. This implies we need a different stream, one keyed to those _two_ factors, not just the room itself. We can easily add that stream to our `rooms/show` view:

```erb
<!-- in app/views/rooms/show.html.erb -->
  <%= turbo_stream_from @room %>
  <%= turbo_stream_from @room, current_user %>

```

To be clear about what's happening here:

* `turbo_stream_from @room` creates a single stream that is common to all viewers in the room, giving us a multicast stream
* `turbo_stream_from @room, current_user` creates a stream that is individual to each user in that room, giving us a much more targeted stream

With that in place, we can direct the replacement broadcast to the new stream in our Messages controller, which will only direct the replacement to the initiating user:

```ruby
  # in app/controllers/messages_controller.rb
  def create
    @message = @room.messages.create(message_params)

    respond_to do |format|
      format.turbo_stream {
        Turbo::StreamsChannel.broadcast_replace_later_to @message.room,  current_user
          target: @message,
          partial: "messages/message",
          locals: { message: @message, current_user: current_user }
      }
      format.html { redirect_to @room }
    end
  end
```

This will immediately overwrite the message in the room for the person who initiated the message creation, and include the 'edit' link as it should.

Well, okay--it will overwrite the message _most_ of the time. Sometimes it doesn't! In fact, we've encountered a race condition: `broadcasts_to` in our Message model and `broadcast_replace_later_to` in the Message controller are both queueing a job. If the model's `broadcast_to` enqueues first, excellent. If not, then the controller's `broadcast_replace_later_to` will not find an element to replace, and will silently fail.

We can solve this in a few ways, but the quick and dirty solution is to sleep for some very small amount of time. Not great, but good enough for our experiment:

```ruby
  # still in app/controllers/messages_controller.rb
    respond_to do |format|
      format.turbo_stream {
        sleep 0.05 # solves the race condition inelegantly
        Turbo::StreamsChannel.broadcast_replace_later_to @message.room, current_user
          # ...
      }
    end
```

Identical behavior surfaces when a Message is updated. We can extract this delayed replacement into a function and reuse it in both places:

```ruby
# from app/controllers/messages_controller.rb

  def create
    @message = @room.messages.create(message_params)

    respond_to do |format|
      format.turbo_stream { send_delayed_replacement(@message) }
      format.html { redirect_to @room }
    end
  end

  def update
    @message.update(message_params)
    respond_to do |format|
      format.turbo_stream { send_delayed_replacement(@message) }
      format.html { redirect_to @room }
    end
  end

  private

  def send_delayed_replacement(message)
    sleep 0.05
    Turbo::StreamsChannel.broadcast_replace_later_to message.room, current_user
      target: message,
      partial: "messages/message",
      locals: { message: message, current_user: current_user }    
  end
```

Worth a mention: this approach results in sending the message twice, but from a traffic point of view that's still small potatoes.

Now that we've fixed what we've broken, we can get around to the first item on our feature list: any user must be able to easily differentiate their own messages in the view.

### Differentiating our own Messages

This isn't as important to the experiment as the actual _function_ of the application (though it would certainly be in a real product), but it's worth doing for the sake of completeness. We wouldn't launch without this kind of experience, so maybe we shouldn't experiment without it either, eh?

We could solve this with code, but this is most expediently solved with CSS. First we add a content area for styles in our layout, and add a data attribute (`data-viewer`) to our `body`:

```erb
  <!-- in app/views/layouts/application.html/erb -->
  <head>
    <!-- other stuff -->
    <style>
      <%= yield :custom_style %>
    </style>
  </head>
  <body data-viewer="<%= current_user&.id %>">
    <!-- more stuff -->
  </body>
```

Adding the attribute to body lets us match on attributes attached to our message elements. Next we'll add an attribute to our message partial:

```erb
<!-- in app/views/messages/_message.html.erb -->
<%= turbo_frame_tag dom_id(message), 
                    data: { sender: message.user.id } do %>
  <!-- message contents -->
<% end %>
```

Finally, we can add styles to our room's show page:

```erb
<!-- in app/views/rooms/show.html.erb -->
<% content_for :custom_style do %>
[data-viewer="<%= current_user.id %>"] turbo-frame[data-sender="<%= current_user.id %>"] {
  text-align: right;
  align-self: flex-end;
  justify-content: flex-end;
}

/* additional styles */

<% end %>

<%= turbo_stream_from @room %>
  <!-- contents -->
<% end %>
```

When this renders, we'll have nested elements with attributes we can make style decisions about. Again, we've removed noise for clarity, but we end up looking like this:

```html

<!DOCTYPE html>
<html>
  <head>
    <!-- head stuff -->
    <style>
      [data-viewer="1"] turbo-frame[data-sender="1"] {
        text-align: right;
        align-self: flex-end;
        justify-content: flex-end;
      }

      /* style stuff */

    </style>
  </head>
  <body data-viewer="1">
    <turbo-cable-stream-source 
      channel="Turbo::StreamsChannel" 
      signed-stream-name="stream-name">
    </turbo-cable-stream-source>
    <div id="messages">
      <turbo-frame data-sender="2" id="message_131">
        <div class="info-block">
          <span>jdoe</span>
          <span>7:40pm</span>
        </div>
        <div>
          message content
        </div>
      </turbo-frame>
      <turbo-frame data-sender="1" id="message_132">
        <div class="info-block">
          <span class="action-block">
            <a href="/rooms/1/messages/132/edit">edit</a>
          </span>
          <span>bvandg</span>
          <span>7:42pm</span>
        </div>
        <div>
          additional message content
        </div>
      </turbo-frame>
    </div>
    <form action="/rooms/1/messages" accept-charset="UTF-8" method="post">
      <input type="hidden" name="authenticity_token" value="authtoken" />
      <div class="flex">
        <input type="text" name="message[comment]" id="message_comment" />
      </div>
    </form>
  </body>
</html>
```

In the `body` element, we end up with a `data-viewer` attribute with a value of `1`.  The first message's `data-sender` value is 2, which doesn't trigger our css matcher: `[data-viewer="1"] turbo-frame[data-sender="1"]`. The _second_ message matches exactly both the attributes and value, and so the styles we've included will apply. Once again, for the real details, have a look at the [source](https://github.com/beflagrant/chatty/tree/hotwire).

With feature #1 wrapped, let's add a little polish with the _other_ part of Hotwire: Stimulus.

### Finishing Touches

If you've read the [previous post](http://beflagrant.com/blog/what), this next section will look a little familiar. Both Hotwire and Stimulus Reflex use Stimulus under the covers to get things _*chef's kiss*_. We have a few small gripes, and will address one of them here.

When we enter a message into our message form at the bottom of the page, it submits on enter, but the text just sits there accusingly. We'd like the text field to reset. Since we're not rendering the page afterward, we have to scrape this clean using JavaScript. [Stimulus](https://stimulus.hotwire.dev/) gives us some neat tools to collect this polish (and even more complex things) into controllers.

First, we'll build the tiniest controller:

```javascript
// either: app/assets/javascripts/controllers/reset_form_controller.js
//     or: app/javascripts/controllers/reset_form_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  reset() {
    this.element.reset()
  }
}
```

It has one function, and that's it. In the context of the controller, `this` refers to the element on which the controller and action are defined. We then add two data elements to our form. These elements identify the controller and the action to perform. In this case, the action takes advantage of a custom event provided by Turbo--`turbo:submit-end`:

```erb
  <%= form_with model: [@room, Message.new],
                data: { 
                  controller: "reset_form", 
                  action: "turbo:submit-end->reset_form#reset"
                } do |f| %>
    <div class="flex">
      <%= f.text_field(
        :comment,
        autocomplete: "off",
        placeholder: "Start a conversation") %>
    </div>
  <% end %>
```

What we're saying is this: load the `reset_form` controller, and on the `turbo:submit-end` event (that is, when the event has returned from its submit) fire the reset() method on that controller. 

Remember the convention here: `event->controller#method`

By following the convention, everything else is automatic. We don't need to modify our `application.js` file, throw dice, yell "Yahtzee" or anything.

That's it, we're done.

## Conclusion

If you've been keeping track, we've been able to accomplish a lot without doing very much at all. In fact, excluding CSS injection, we've completed our feature list after installing hotwire with just 30 lines of code, 8 of which are boilerplate or `end` statements. That's a very solid value for bytes spent.

Remember that both Turbo and Stimulus have a fair lineage, so it's not surprising that things worked largely out of the box, save for the race condition we encountered.

In the [next post](), we'll summarized what we've learned so far, and draw some comparisons and real conclusions from these experiments.

