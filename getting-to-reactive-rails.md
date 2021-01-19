# Reactive Rails in Context

At [Flagrant](http://beflagrant.com), we recently began designing a chat-centered product. As we were reaching for React, Basecamp dropped [hotwire](https://hotwire.dev/). This gave us pause--by and large, React includes a lot of overhead, and some members of the team make an unpleasant face when React gets mentioned.

We decided to take a step back and examine the state of the art in the Rails world. Would Hotwire get us where we needed to go? Were there other reactive frameworks in wide use that we hadn't considered? So we began to explore, and we'll release our opinions shortly. In the meantime, we took a _second_ step back and considered the context and motivation for reactive programming in general, and Rails specifically.

## Now: Single Page Apps

Currently a movement within the Rails community seeks to abandon the single page app (SPA) development model--that is, an app that lives in the browser and makes (typically RESTful) calls to a service for CRUD operations. Rather than using React, Angular, Vue, or another front-end framework to build an SPA, it's possible to build productive and performant applications without committing to an effectively separate application written in (or transpiled to) JavaScript (JS) 

Why depart from such a popular model? Simplicity ranks highly--a single codebase instead of two, with tooling instead of hand-rolled solutions means less code needs to be written, maintained, and kept in sync. The code we _do_ have to write can be kept to (mostly) one language, rather than an even split between Ruby and JavaScript. This means getting more done quickly, less to test, and a more uniform development experience. All of which tends to mean a higher-quality product, happier developers, and happier customers.

Perhaps the most compelling reason, however: the SPA model isn't great for every case. Arguably, it's not great for _most_ cases. It's a trend that evolved to address the difficulty of maintaining complex application state when using an underlying protocol that remains stateless (HTTP). With the advent of non-HTTP options including stateful connections (e.g., WebSockets) and richer request options (e.g., GraphQL), the SPA model solves a problem that no longer exists.

Using this approach as the current default (as many organizations do) means you're often inheriting much more complexity than you need. Multiple languages, dependency management systems, build processes, and release activities. Mostly, YAGNI. Better approaches exist. Two years ago? Different story. So let's walk through _those_ stories first. Afterward, we'll look at a few approaches using Rails with reactive programming techniques--collectively dubbed _Reactive Rails_--that are available in early 2021.

## Then: Historical Approaches

### HTTP(S) Request/Response

At any time, the techniques we choose to employ when developing web-based applications in Rails the techniques have to consider horsepower, currently-available technology, and trends within development communities. Traditional, vanilla Rails applications (pre-1.0, circa 2004) serviced HTTP requests and responded with rendered HTML. 

Few Rails developers build applications like this 17 years later, but that's the Rails baseline: request a page/resource, get a fully-rendered HTML response. Navigate to a different page in your browser, submit a form, get another fully-rendered page including your results. Lather, rinse, repeat.

### Asynchronous HTTP(S) Request/Response

While the first draft spec of the XMLHttpRequest object landed in 2006, early technologies served similar purposes. The term AJAX (as Asynchronous JavaScript and XML) had been in use since early 2005. Very quickly after some standards allowed for cross-browser compatability, we began to see applications designed with some asynchrony--a user causes an event (say, by clicking a 'submit' or 'search' button) and an async HTTP request is sent to a Rails endpoint returning HTML or XML data[^1], which then causes an adjustment in the page, driven using some JavaScript.

Initially, these behaviors could be effected with hand-coded JS using its included functions or using the JQuery library. (Raise your hand if you remember implementing infinite scrolling using jQuery and the `will_paginate` gem.) After a few years, the frameworks began catching up.

### Unobtrusive JavaScript and Cross-View State

Starting at version 3.0 (mid-2010), these facilities began to be baked into Rails as _unobtrusive JavaScript_ (think `:remote => true`). When used as initially intended, this yielded endpoints that could serve both XML or HTML depending on what is sought (`things[.json]/77`), or just as commonly a mish-mash of endpoints for rendered pages (`/things/77`) and data endpoints (`/api/things/77`) for data. Better, but not great. The big win: unobtrusive JavaScript decreased the amount of custom JS that a developer had to write and maintain.

As networks and browsers and their underlying hardware became faster (including mobile hardware--the first iPhone was release in 2007), more functionality began living in the browser, with increasingly complex frameworks to support it[^2]. Mostly, these frameworks sought to solve the problem of data consistency across views. Web storage was still in its infancy and limited to string key/value pairs.[^3]

### Single Page Applications

The question naturally arose: why not put the entire application in the browser? In 2010, AngularJS (1.0) was released by Google. A decent first swing, but the long-term winner was React, released in 2013. Since then, the app-in-the-browser idea, with an API somewhere to handle data requests has been increasing in popularity, becoming a _de facto_ standard. Why did this become a trend in developing web-based applications? Because it was possible, it mostly solved the data consistency problem, and because quite a few developers reasoned that 'if Facebook is doing it this way, it must be the right way'[^4].

Part of the less technical appeal of this approach was the illusion of easy-to-get-started tooling that gave you a rapid development environment and you could get to market more quickly. Also, the appeal of easy-to-hire and inexpensive JS developers fresh from a code boot camp where they learned how to build React apps and deploy them on Netlify and communicate with a Mongo backend. It appealed to CIOs when they were considering the budget handed to them by CFOs. These conversations almost never considered the considerable cost to send these young Jedi to the Dagobah system to complete their training.

A perceived demand among users to have a 'seamless experience', along with an actual demand for a snappy response to actions also drove the adoption of the SPA/API application model, though neither of those things were guaranteed--or even more likely--using this application model.

One final driver for this approach: building a SPA meant you didn't really have to build two or more native mobile applications right out of the gate, provided you didn't need to interface with the mobile device's hardware.

And so for the past several years many developers start a new project by reaching for [`create-react-app`](https://create-react-app.dev/) or [Vue.js](https://vuejs.org/) or similar frameworks. Many organizations just accept that a lot of the complexity of their applications are going to live in JavaScript or TypeScript and a multi-gigabyte `node_modules` directory will exist that we occasionally have to delete and repopulate. Individual developers consider building furniture for a living or perhaps raising vegetables.

Given that we've been using this approach for a decade now, has it improved the quality of web-based applications? Are they snappier? Are there seamless experienced to be had? Do we have enough evidence now to understand that the SPA approach isn't any kind of panacea, and if not then why continue it?

Questions like these, along with the productivity gains from being able to write an application (mostly) in a single language, developed by a single team have revived an interest among many developers in the reactive programming model and in building frameworks to support it.

## Soon: Reactive Rails

At its core, reactive programming concerns itself with _reacting_ asynchronously to messages delivered over a (usually persistent) data stream. In the web application world, reactive web programming becomes possible and consistent with WebSockets (2011) providing persistent, stateful streams. This allows for states across views being managed on the server instead of the browser. A pleasant side-effect: using a WebSocket eliminates most of the overhead of individual HTTP requests and responses.

Reactive programming isn't new[^5]. The bones of this approach appear in modern software languages as early as 2005. On the hardware and systems programming side, the Intel introduced the 8259 Programmable Interrupt Controller (PIC) in 1976--this allowed for reactive operating system events driven by hardware. 

We see the beginnings of this approach with the release of ActionCable in Rails 5 (2015). It has come into its own with libraries like CableReady (2017) in the Rails world, and Phoenix LiveView (mid-2019) in Elixir, among many, many others[^6]. (The term 'Reactive Rails' would come somewhat later[^7].)

Reactive Rails applications use libraries layered atop ActionCable to do most of the heavy lifting. In general, a lightweight communication handler lives in the browser, connects to the server, and manages messaging. Each side reacts to messages that it receives. These messages are often in the form of an action to take, incoming data, or (preferably atomic) changes[^8].

The core idea: a lightweight comms piece in the browser creates a connection to the server. That connection persists throughout the lifespan of the page. Browser and server share a common message protocol, and each side _reacts_ to the message it receives, often in the form of an action to take, incoming data, or other (preferably atomic) change[^7]. Typically, the server will react to requests for data or changes to data, and the client will react by updating the contents of the browser/DOM, but simple client-server interaction is only the beginning.

Especially if you're about to build a selective multicast communication system.

Next time: [Stimulus Reflux and Hotwire, Compared]

---

### Footnotes

[1]: JSON wouldn't be standarized until 2013

[2]: for example, Backbone.js and Knockout.js were released in 2010, Ember in 2011

[3]: [Web Storage--W3C Working Draft 23 April 2009](https://www.w3.org/TR/2009/WD-webstorage-20090423)

[4]: this article was written around january 6, 2020. whether or not FB had been doing the right thing in any respect is left for the reader to ponder

[5]: [Reactive imperative programming with dataflow constraints, OOPSLA '11](https://dl.acm.org/doi/10.1145/2048066.2048100), [Deprecating the Observer Pattern](infoscience.epfl.ch/record/148043/files/DeprecatingObserversTR2010.pdf?version=1)

[6]: Reactive Rails Libraries:
  * [Stimulus](https://stimulusjs.org/)
  * [CableReady](https://cableready.stimulusreflex.com/)
  * [Stimulus Reflex (Stimulus + CableReady)](https://docs.stimulusreflex.com/)
  * [Turbo](https://turbo.hotwire.dev/)
  * [Hotwire (Turbo + Stimulus)](https://hotwire.dev/)
  * Not a Complete List

[7]: [Reactive Rails Applications with Stimulus Reflex](https://dev.to/finiam/reactive-rails-applications-with-stimulusreflex-48kn), for example

[8]: this creates problems with transactionality in some use cases, especially when changes are built up over a period of communication, but that's another show
