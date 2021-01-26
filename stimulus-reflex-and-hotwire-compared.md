# Reactive Rails: Considering Stimulus Reflex and Hotwire

by Jonathan Greenberg, Ben Vandgrift

## Introduction

At [Flagrant](http://beflagrant.com), we recently began designing a chat-centered product. As we were reaching for React, Basecamp dropped [Hotwire](https://hotwire.dev/). This gave us pause--by and large, React includes a lot of overhead, and some members of the team make an unpleasant face when React gets mentioned.

We decided to take a step back and examine the state of the art in the Reactive Rails world. Would Hotwire get us where we needed to go? Were there other reactive frameworks in wide use that we hadn't considered?

### Reactive Rails?

There is a movement in the Rails community to abandon the single page app (SPA) backed by web-based services (API) pattern and replace it with productive and performant ways to create apps in Rails that satisfy those needs. For Rails enthusiasts, productivity can be increased by requiring less custom code, and less JavaScript to write and debug.

If you'd like a short primer on where these notions come from, we provide a broader context [here](https://beflagrant.com/blog/article-name).

### Motivations

The ever-changing landscape of software development rewards personalities that love to learn new things. This has an obvious drawback: the desire to _use_ that new thing as soon as it appears, even if it's not fully baked. Whether or not to implement a solution using the new and shiny is an exercise in judgement (and restraint). We have to evaluate each new technology in a few ways:

* fitness of purpose
* support and adoption
* stability of core assumptions
* security
* introduced uncertainty
* effect on development speed
* happiness

These are the factors in our minds as we evaluated these two technologies. Staying on top of the state of the art is a worthwhile endeavor. Actually _using_ the state of the art means asking difficult questions. A decision to make use of a new things should only come after these questions have satisfactory answers.

### Overview

Our process, in brief:

First, we built a simple chat prototype in the vanilla Rails way. From there, we plugged Hotwire into the prototype to see how well it fit our purpose. In short, we bumped into some walls and it didn't meet our needs out of the box. This was unsurprising given its shiny newness.

That prompted us to look for another solution in the same vein. We decided on StimulusReflex](https://docs.stimulusreflex.com/) and its underlying library [CableReady](https://cableready.stimulusreflex.com/), based on its growth in popularity and recommendations over the past year. This framework boasts more thorough documentation and has had time in the community to get banged around some.

We found Stimulus Reflex to be a much better fit for our purposes. It has some drawbacks: the learning curve is non-trivial, and we ended up writing more JavaScript than we'd hoped.

The rest of this post will be a deeper dive into those evaluations.

## Getting Started

We have two goals in mind: first, to find a solution that provides the functionality we need from a single page app without the associated overhead. Second, we want to add tools to our belt making this kind of activity easier in future projects.

Our specific application needs an interactive communication channel between users, with advanced chat and file/photo sharing capabilities encapsulated into a single view. Think of an advanced group text and you've got the idea. Required features for our prototype:

1) Any user must be able to easily differentiate their own messages in the view
2) Any user must be able to edit only their own messages
3) Every user sees updates in real time

This is a small subset of features we felt would enable us to compare and contract the pros and cons of Hotwire and Stimulus Reflex in relative isolation. We kept the problem domain small enough that we wouldn't lose focus, but complex enough to ensure we pushed some of the edges of these tools.

Hotwire and Stimulus Reflex appear to be roughly aligned philosophically and rely on similar underlying tools (Rails, ActionCable, and Stimulus), and so we can approach an apples to apples comparison between these two.

### Bare Bones

To form a foundation for both experiments, we built a lean, vanilla Rails application, intending to implement Stimulus Reflex and Hotwire solutions in separate branches. You can check out the base code for [chatty here](https://github.com/beflagrant/chatty). We built it using Rails 6.1 and Ruby 2.7.2.

For models, we limited ourselves to three: User, Room, and Message. We've left out real authentication, and simply track the current user using a `user_id` in the session. Because we appreciate some style, we also incorporated [Tailwind CSS](https://tailwindcss.com/). We opted for Webpacker over Sprockets and the asset pipeline. Setup will seed a single room in the database for everyone to share.

The result? A basic chatroom experience:

[SCREEN SHOT]

Of course, this bare app requires a full page refresh when submitting new content, and doesn't update other users' views.

At this point, we have a blank canvas from which to integrate both solutions and see where we are. We'll start with Hotwired.

QUESTIONS TO ANSWER:

How difficult to add to a new project?
How easy to integrate into an existing project? (Given webpacker vs sprockets.)
What dependencies does it bring to the party?
Special concern: for an existing API driven project w/ a React front end, how
‘expensive’ is it to convert?
What is the learning curve of each project? How good is the documentation?
How fast can one get to a minimal/prototypical implementation?


### First Impression: Hotwired

[NEEDS A BUNCH OF WORK]

After watching the first-out (and detail-light) Hotwire videos ([GoRails hotwire-rails](https://gorails.com/episodes/hotwire-rails),  [Hotwire Demo](https://www.youtube.com/watch?v=eKY-QES1XQQ&ab_channel=GettingReal)) it was time to see how well it worked with our simple chat app prototype.

Well, I was a bit disappointed but not too surprised when I started bumping into some challenges since this technology is freshly released and though obviously being exercised by Basecamp with their new [Hey email service](https://hey.com/) it has not been battle tested by the masses until now. 

While the basic Turbo Frame and Turbo Stream patterns work fine for simple use cases one needs to get creative for more complicated use cases. In our case we wanted new messages to appear different to different users and in particular the current user sending the message. Unfortunately, Turbo currently only supports sending one version of a partial over action cable turbo streams and the general advice is to find your own solutions using Stimulus in such cases (see [this issue](https://github.com/hotwired/turbo-rails/issues/47)). 

### First Impression: Stimulus Reflex

StimulusReflex had been making a splash in recent years and especially the last few months: GoRails created an [introductory video](https://gorails.com/episodes/stimulus-reflex-basics) in mid-April of 2020, and less than two weeks later the SR team released a [twitter clone demo video](https://www.youtube.com/watch?v=F5hA79vKE_E&ab_channel=Hopsoft) of their own. Both videos promote using SR rather than heavy front-end frameworks. It would be eight months between these videos and the release of Hotwire.

The documentation and instrumentation for CR/SR seem quite mature and the development team is surprisingly accessible, friendly and generous on their [Discord Channel](https://discord.gg/XveN625). This made integrating Stimulus Reflex straightforward, with a good human fallback if any hiccups happen.

At its core Stimulus Reflex is a set of patterns that provides some glue between Stimulus js and CableReady. Like Hotwire, CableReady provides a mechanism to update the DOM by sending mostly HTML and operations to the client; however, unlike Hotwire, CableReady solely depends on WebSockets[^fn1]  for communication while Hotwire only uses ActionCable for its Turbo Stream feature. It is also worth noting that StimulusReflex leans on a cool js project [morphdom](https://github.com/patrick-steele-idem/morphdom) for some of its more advanced manipulations of the DOM. 

Installation of StimulusReflex is pretty trivial following their docs but basically the steps were:

```sh
bundle add stimulus_reflex
bundle exec rails stimulus_reflex:install
```

With Stimulus Reflex installed, we can move on to integrating it with our bare bones application.

### Integrating Stimulus Reflex

The model we'll be using Stimulus Reflex to manage is the Message, so we first need to generate the reflex classes we'll build on:

```sh
rails g stimulus_reflex message
```

This will create `application_controller.js` and `message_controller.js` files in `app/javascript/controllers`, and create `application_reflex.js` and `message_reflex.js` in `app/reflexes`. We'll put the SR-specific JavaScript in those files.

The first test in our app was to see how StimulusReflex did with broadcasting new messages to all client streams. This is where the fun magic of ActionCable WebSockets transform our boring one-way chatroom into a multi-person realtime conversation. Of course, as mentioned earlier, the simple broadcast of identical messages to all room members is quite trivial both for StimulusReflex and Hotwire so we dug right in to figure out a way to broadcast different html to different users.

We got a tip almost immediately from the attentive support on the SR Discord channel to check out [The Logical Splitter Example](https://cableready.stimulusreflex.com/leveraging-stimulus#example-3-the-logical-splitter) in the docs. At a later point we were also advised to explore CableReady's extensible [Custom Operations](https://cableready.stimulusreflex.com/customization#custom-operations). Following these two ideas we came up with this solution:

First, we prepare our application layout. Inserting the user's id as a `meta` tag in the head of the layout will provide us with a reference we will use at later:

```erb
<%# in app/views/layouts/application.html.erb %>

<%= tag(:meta, name: :cable_ready_id, content: current_user&.id) %>
```

In our `MessageReflex` class, we specify that when created via reflex, the message should broadcast two html snippets, one for the html that everyone in the room will see (`default_html`), one snippet that is rendered when the current user is the author of the message (`custom_html`):

```ruby
# in app/reflexes/message_reflex.rb
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

In many circumstances, there's no need to build all of this custom code. CableReady provides a diverse and comprehensive array of [operations](https://cableready.stimulusreflex.com/reference/operations) out of the box to manipulate the DOM and interact with the browser. We built a custom operation specifically because we wanted different visuals to highlight messages posted by the current user, which _doesn't_ happen out of the box. (Recall that in our Hotwire implementation, we did this using CSS.)

[THIS IS AS FAR AS I'VE GOTTEN]

One neat feature of CableReady is that is can be used almost [anywhere](https://cableready.stimulusreflex.com/cableready-everywhere) in your Rails app and indeed it would have been fine to leave the operation call as a regular form submit to the controller:

```ruby
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

with our original form unchanged:

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

However, for fun, practice and code organization we moved the logic into a reflex and we're now able to demonstrate submitting a comment without a form at all:

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

Students of Stimulus will quickly recognize the familiar syntax that reflexes borrow for their data-reflexes. They will also detect that our wrapping div wraps our reflex in a stimulus controller. This allows us to benefit from the [client side callbacks](https://docs.stimulusreflex.com/lifecycle#client-side-reflex-callbacks) that StimulusReflex so graciously provides for all reflexes. So in our controller we can have the following little "sprinkle" of js to clear our input after the change successfully triggers the create reflex: 
```javascript
   createSuccess(element) {
     element.value = ''
   }
```
  Looking back at the reflex above you will note the call to `morph :nothing`. This is because we are overriding the default behavior of reflexes and using CableReady directly ourselves. However, we can show case the power of the default morph behavior of reflexes as we tackle the next chat feature of editing messages. 

This is a good moment to also check out our message partial which like Hotwire and really Rails in general is what StimulusReflex with reach to by default when rendering an object: 

```ruby
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

Lots going on here since the partial is handling our logic and presentation for messages to the author of the receiver and not as well as when the message is being edited. My guess is that [ViewComponents](https://docs.stimulusreflex.com/patterns#viewcomponentreflex) another popular library for Reactive Rails developers and supported by StimulusReflex might help organize this view but that was more than I wanted to take on for this exercise. Anyhow, with the aid of this helper: 

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
we are able to inform the partial how to render the content for different users depending on whether they are the messenger or not both on a full page refresh and when broadcasting the logical split operation to be determined on the client side. 

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

#### Quick Reflexes


## Footnotes

[fn1]: Stimulus Reflex uses ActionCable by default. [Integration with AnyCable](https://docs.stimulusreflex.com/deployment#anycable) is possible as well.