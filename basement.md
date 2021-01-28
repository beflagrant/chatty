# Basement

from the introduction: 

Why are we doing this?
Stimulus Reflex - established
Hotwire/Turbo - new hotness
With a new reflexive offering, it’s a good time to compare to existing options,
and see whether (for established SR users) switching/exploring is a good idea,
and (for all new adoption) which framework is best in which situations.

Quirk 1: `./bin/rails hotwire:install` yielded a missing gem: `redis`. Had to
re-run `bundle install` but then all was well.


eval criteria before shortening:

* does it serve our purpose out of the box, or will we need to adapt our product to the quirks of the new technology?
* what level of support and adoption is the new technology likely to have?
* will the initial assumptions remain true as the technology develops? will we need to adjust with every new release?
* are there any security considerations introduced by this new technology?
* how much uncertainty does the new technology introduce?
* will this speed up or slow down development? if it slows down development, what features makes that worthwhile?

 ([GoRails hotwire-rails](https://gorails.com/episodes/hotwire-rails), [Hotwire Demo](https://www.youtube.com/watch?v=eKY-QES1XQQ&ab_channel=GettingReal))

Given that Hotwire is freshly released, it's not surprising that we began bumping into some walls. While 37 Signals makes production use of Hotwire
in their [Hey email service](https://hey.com/) it has not been battle tested by the broader development community until now. While it performs as advertised, it didn't suit our purposes out of the box. Given its shiny newness, there isn't a large body of documentation and experience reporting to draw from.

That prompted us to look for another solution in the same vein. We decided to explore [StimulusReflex](https://docs.stimulusreflex.com/) and its underlying library [CableReady](https://cableready.stimulusreflex.com/), based on its growth in popularity and recommendations over the past year. This framework boasts more thorough documentation and has had time in the community to get banged around some.

When plugging in Stimulus Reflex to our bare rails app, we found it to be a much better fit based on capabilities. It has some drawbacks: the learning curve is non-trivial, and we ended up writing more JavaScript than we'd hoped.

The rest of this post will be a deeper dive into our evaluation.

---

I want to include this here, and backport these into the series. --ben

QUESTIONS TO ANSWER:

How difficult to add to a new project?
How easy to integrate into an existing project? (Given webpacker vs sprockets.)
What dependencies does it bring to the party?
Special concern: for an existing API driven project w/ a React front end, how
‘expensive’ is it to convert?
What is the learning curve of each project? How good is the documentation?
How fast can one get to a minimal/prototypical implementation?


---

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