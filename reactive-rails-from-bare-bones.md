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

## The Bare Bones

To form a foundation for both experiments, we built a lean, vanilla Rails application, intending to implement Stimulus Reflex and Hotwire solutions in separate branches. You can check out the base code for [chatty here](https://github.com/beflagrant/chatty). We built it using Rails 6.1 and Ruby 2.7.2.

For models, we limited ourselves to three: User, Room, and Message. We've left out real authentication, and simply track the current user using a `user_id` in the session. Because we appreciate some style, we also incorporated [Tailwind CSS](https://tailwindcss.com/). We opted for Webpacker over Sprockets and the asset pipeline. Setup will seed a single room in the database for everyone to share.

The result? A basic chatroom experience:

[SCREEN SHOT]

Of course, this bare app requires a full page refresh when submitting new content, and doesn't update other users' views.

## Next Up

At this point, we have a blank canvas from which to integrate both solutions and see where we are. The next two posts will explore StimulusReflex and Hotwired individually. Finally, we'll compare, contrast, and summarize our thoughts.

