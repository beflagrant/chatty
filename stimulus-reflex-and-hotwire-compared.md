# Reactive Rails: Considering Stimulus Reflex and Hotwire

by Jonathan Greenberg, Ben Vandgrift

## Introduction

At [Flagrant](http://beflagrant.com), we recently began designing a chat-centered product. As we were reaching for React, Basecamp dropped [hotwire](https://hotwire.dev/). This gave us pause--by and large, React includes a lot of overhead, and some members of the team make an unpleasant face when React gets mentioned.

We decided to take a step back and examine the state of the art in the Reactive Rails world. Would Hotwire get us where we needed to go? Were there other reactive frameworks in wide use that we hadn't considered?

### Reactive Rails?

There is a  movement in the Rails community to abandon the single page app (SPA) backed by web-based services (API) pattern and replace it with productive and performant ways to create apps in Rails that satisfy those needs. For Rails enthusiasts, productivity can be increased by requiring less custom code, and less JavaScript to write and debug.

If you'd like a short primer on where these notions come from, we provide a broader context [here](https://beflagrant.com/blog/article-name).

In this next bit, we'll talk about reactive programming (and functional reactive programming) generally, and what reactive Rails means specifically. First however, let's roll forward through time, shall we? (If you don't want the recap just the crunchy bits, feel free to <a href="#crunch">skip ahead</a>.)

When developing a web-based application in Rails, there have been a variety of approaches, informed by available horsepower, current technology and trends within development communities. Traditional, vanilla Rails applications (pre-1.0, circa 2004) serviced HTTP requests and responded with rendered HTML. Few Rails developers build applications like this 17 years later, but that's the Rails baseline: request a page/resource, get a fully-rendered HTML response. Navigate to a different page in your browser, submit a form, get another fully-rendered page including your results. Lather, rinse, repeat.

While the first draft spec of the XMLHttpRequest object landed in 2006, early technologies served similar purposes. The term AJAX (as Asynchronous JavaScript and XML) had been in use since early 2005. Very quickly after some standards allowed for cross-browser compatability, we began to see applications designed with some asynchrony---a user causes an event (say, by clicking a 'submit' or 'search' button) and an async request is sent to a Rails endpoint returning HTML or XML data[^1], which then causes an adjustment in the page, driven using some JavaScript (JS).

Initially, this could be effected with hand-coded JS using its included functions or using the JQuery library. Starting at version 3.0 (mid-2010), these facilities began to be baked into Rails as 'unobtrusive javascript' (think `:remote => true`). When used as initially intended, this yielded endpoints that could serve both XML or HTML depending on what is sought (`things[.json]/77`), or just as commonly a mish-mash of endpoints for rendered pages (`/things/77`) and data endpoints (`/api/things/77`) for data. Better, but not great.

As networks and browsers and their underlying hardware became faster (including mobile hardware--the first iPhone was release in 2007), more functionality began living in the browser, with increasingly complex frameworks to support it[^2]. Data was beginning to be shared across consistently across views.

The question naturally arises: why not put the entire application in the browser? In 2010, AngularJS (1.0) was released by Google. A decent first swing, but the long-term winner was React, released in 2013. Since then, the app-in-the-browser idea, with an API somewhere to handle data requests has been increasing in popularity. Why did this become a trend in developing web-based applications? Because it was possible, and because quite a few developers reasoned that 'if Facebook is doing it this way, it must be the right way'[^3].

As a result, for the past several years, developers have reached for [`create-react-app`](https://create-react-app.dev/) to start a new project, or [Vue.js](https://vuejs.org/) or similar frameworks, and many organizations just accept that a lot of the complexity of our application is going to live in JavaScript or Typescript. Individual developers consider building furniture for a living or perhaps raising vegetables.

Part of the appeal of this approach is the illusion of easy-to-get-started tooling that gives you a rapid development environment and you can get to market more quickly. Also, the appeal of easy-to-hire and inexpensive JS developers fresh from a code boot camp where they learned how to build React apps and deploy them on Netlify and communicate with a Mongo backend. It appeals to CIOs when they are considering the budget handed to them by CFOs. These conversations almost never consider the considerable cost to send these young Jedi to the Dagobah system to complete their training.

A perceived demand among users to have a 'seamless experience', along with an actual demand for a snappy response to actions also drives the adoption of the SPA/API application, though neither of those things are guaranteed--or even more likely--using this application model.

Given that we've been using this approach for a decade now, has it improved the quality of web-based applications? Are they snappier? Are there seamless experienced to be had? We have enough evidence now to understand that the SPA approach isn't any kind of panacea, and if not then why continue it?

Questions like these, along with the obvious productivity gains from being able to write an application (mostly) in a single language, developed by a single team have revived an interest among many developers in the reactive programming model and the frameworks built to support it. We can see the beginnings of this surrounding the release of ActionCable in Rails 5 (2015), and coming into its own with libraries like CableReady (2017) in the Rails world, and Phoenix LiveView (mid-2019) in Elixir, among many, many others. (The term 'Reactive Rails' would come somewhat later[^4].)

To get this out of the way, reactive programming isn't new[^5]. The bones of this approach appear in modern software languages as early as 2005, and the Intel 8259 Programmable Interrupt Controller (PIC) was introduced in 1976. At it's core, reactive programming concerns itself with reacting asynchronously to messages delivered over a data stream.

 Because of how reactive programming tends to be structured, a communication r

Reactive Rails applications (and other reactive programming efforts) tend to use connected data streams (as opposed to disconnected and stateless HTTP requests) to push messages back and forth between the browser and the service. With WebSockets, as implemented by ActionCable and the libraries layered atop it, this becomes possible in Rails without too much heavy lifting. By connecting once (per stream) and keeping the connection open, the connection/disconnection overhead is recovered. By keeping the messages small and their handling simple and concise, the computational and memory overhead is recovered. Since it's always connected, the message exchange time decreases, sometimes dramatically.

The core idea: a lightweight comms piece in the browser creates a connection to the server. That connection persists throughout the lifespan of the page. Browser and server share a common message protocol, and each side _reacts_ to the message it receives, often in the form of an action to take, incoming data, or other (preferably atomic) change[^6]. Typically, the server will react to requests for data or changes to data, and the client will react by updating the contents of the browser, but simple client-server interaction is only the beginning.

Especially if you're about to build a selective multicast communication system.

[STOP]

Hotwire is Basecamp's latest contribution to a growing movement in the Rails community to abandon the SPA philosophy and find productive and performant ways to create applications that rely on Rails as more than just an api backend. 

I will not spend too much time explicating all the reasons and justifications for moving back to a more backend centric approach to web applications since others have already done that quite well (you can refer to [this guide](https://github.com/obie/guide-to-reactive-rails) for a pretty comprehensive list of resources). Suffice it so that while javascript is invaluable for creating a more dynamic browser experience for clients that should not nor need not be at the cost of the development ease and maintainability of the application. Keeping the logic and state of a website in one place is just good basic software principles and for Ruby programmers that is likely to be on the server side. 


Why are we doing this?
Stimulus Reflex - established
Hotwire/Turbo - new hotness
With a new reflexive offering, it’s a good time to compare to existing options,
and see whether (for established SR users) switching/exploring is a good idea,
and (for all new adoption) which framework is best in which situations.

Quirk 1: `./bin/rails hotwire:install` yielded a missing gem: `redis`. Had to
re-run `bundle install` but then all was well.

## Getting Started <a id="crunch"/>

How difficult to add to a new project?
How easy to integrate into an existing project? (Given webpacker vs sprockets.)
What dependencies does it bring to the party?
Special concern: for an existing API driven project w/ a React front end, how
‘expensive’ is it to convert?
What is the learning curve of each project? How good is the documentation?
How fast can one get to a minimal/prototypical implementation?

## Specific Features

This starts the conversation on what is good for what type of application, and
where the trade-offs live.
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

## First Attraction



## First Taste
So after watching the first splash of tantalizing Hotwire videos ([GoRails hotwire-rails](https://gorails.com/episodes/hotwire-rails),  [Hotwire Demo](https://www.youtube.com/watch?v=eKY-QES1XQQ&ab_channel=GettingReal)) it was time to see how well it worked with our simple chat app prototype.

Well, I was a bit disappointed but not too surprised when I started bumping into some challenges since this technology is freshly released and though obviously being exercised by Basecamp with their new [Hey email service](https://hey.com/) it has not been battle tested by the masses until now. 

## Second Thoughts
While the basic Turbo Frame and Turbo Stream patterns work fine for simple use cases one needs to get creative for more complicated use cases. In our case we wanted new messages to appear different to different users and in particular the current user sending the message. Unfortunately, Turbo currently only supports sending one version of a partial over action cable turbo streams and the general advice is to find your own solutions using Stimulus in such cases (see [this issue](https://github.com/hotwired/turbo-rails/issues/47)). 

Happily, that got me googling around to see what else was out there. Of course Hotwire is a bit too green for much content to be out there just yet but there were a lot of references to another great project called [CableReady](https://cableready.stimulusreflex.com/) and its child project but maybe better known [StimulusReflex](https://docs.stimulusreflex.com/). 

I guess I have been heads down lately because StimulusReflex was already spreading a big wake in recent years and especially the last few months. The SR team made their own impressive [twitter clone demo video](https://www.youtube.com/watch?v=F5hA79vKE_E&ab_channel=Hopsoft) earlier this year and GoRails [started advocating](https://gorails.com/episodes/stimulus-reflex-basics) for this powerful tool for creating great user interfaces without relying on heavy front end frameworks months before the build up to Hotwire. Moreover, the documentation and instrumentation for CR/SR seem quite mature and the dynamic team is surprisingly accessible, friendly and generous on their [Discord Channel](https://discord.gg/XveN625). 

## Taste Test
So now with two great options for prototyping our chat app in the running we had a difficult choice to make. Ultimately, in an ideal world there is no need to choose. These technologies are certainly aligned philosophically and rely on very similar underlying tools (Rails, Stimulus and ActionCable to name some obvious examples). Most likely over time it will become clear which use cases beacon to their respective tools in the box. Nevertheless, when dealing with applying new technologies it often helps to isolate and focus learning so as to not get too overwhelmed and confused. 

To get a better perspective on our options we decided to build a small subset of a chat application to compare and contrast the pros and cons of Hotwire and CR/SR. Of course you can already find plenty of chat example projects out there but there is nothing like writing code yourself. Moreover we wanted to make sure we pushed some of the edges of these tools by implementing some pretty basic chat features, namely:  

1) Users being able to differentiate their messages in a conversation
2) Users being able to edit their message and have them update in multiple streams. 

## Bare Bones
The first step was to create a vanilla rails app with some minimal modeling and rough interface to branch off of. You can check out the base code for [chatty here](https://github.com/beflagrant/chatty). It is a rails 6.1 app on ruby 2.7.2 with just three models User, Room, Message. There is no real authentication but just a simple tracking of the current user using a session user_id. We used tailwind for css and stuck with Webpacker for assets thus far. There is just one room seeded for the database. Just using some basic restful crud for messages you get this basic looking chatroom experience: 

Of course this primitive interface requires a full page refresh for each new message submit and obviously does not update the message stream for any other clients watching the room. 

## Quick Reflexes

At its core Stimulus Reflex is a set of patterns that provides some glue between Stimulus js and CableReady. Like Hotwire, CableReady provides a mechanism to update the DOM by sending mostly HTML and operations to the client; however, unlike Hotwire, CableReady solely depends on WebSockets (ActionCable by default though [integration with AnyCable](https://docs.stimulusreflex.com/deployment#anycable) is possible as well) for communication while Hotwire only uses ActionCable for its Turbo Stream feature. It is also worth noting that StimulusReflex leans on a cool js project [morphdom](https://github.com/patrick-steele-idem/morphdom) for some of its more advanced manipulations of the DOM. 

Installation of StimulusReflex is pretty trivial following their docs but basically the steps were: 

```sh
bundle add stimulus_reflex
bundle exec rails stimulus_reflex:install

rails g stimulus_reflex Message
```

The first test in our app was to see how StimulusReflex did with broadcasting new messages to all client streams. This is where the fun magic of ActionCable WebSockets transform our boring one-way chatroom into a multi-person realtime conversation. Of course, as mentioned earlier, the simple broadcast of identical messages to all room members is quite trivial both for StimulusReflex and Hotwire so we dug right in to figure out a way to broadcast different html to different users. 

We got a tip almost immediately from the attentive support on the SR Discord channel to check out [The Logical Splitter Example](https://cableready.stimulusreflex.com/leveraging-stimulus#example-3-the-logical-splitter) in the docs. At a later point we were also advised to explore CableReady's extensible [Custom Operations](https://cableready.stimulusreflex.com/customization#custom-operations). Following these two ideas we came up with this clever combination: 

```javascript
// app/javascript/packs/application.js

import CableReady from 'cable_ready'

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

```ruby
<%# in app/views/layouts/application.html.erb %>

<%= tag(:meta, name: :cable_ready_id, content: current_user&.id) %>
```

```ruby
# app/reflexes/message_reflex.rb
  delegate :current_user, to: :connection
   
  def create
    message = room.messages.create(comment: element.value, user: current_user)

    message_broadcast(message, "##{dom_id(@room)}", :insertAdjacentHtml)
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
```
And the channel setup as outlined in the manual: 
```javascript
//app/javascript/controllers/room_controller.js
                                                                         
import { Controller } from "stimulus"
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
```ruby
class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_for Room.find(params[:id])
  end
end
```

So far this is just CableReady working its magic allowing an html loaded payload to be broadcasted to all subscribers to a particular room channel. Normally you can rely on the diverse and comprehensive array of [operations](https://cableready.stimulusreflex.com/reference/operations) that CableReady provides out of the box to manipulate the DOM and interact with the browser. Our custom operation allows for tailored signature that augments the base operations allowing us to target different users with different html that is then matched by their meta tag user_id on the front end. 

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

However, for fun, practice and code organization we moved the logic into a reflex and were now able to demonstrated submitting a comment without a form at all: 
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


