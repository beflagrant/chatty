# Hotwire Notes

## Introduction

Why are we doing this?
Stimulus Reflex - established
Hotwire/Turbo - new hotness
With a new reflexive offering, it’s a good time to compare to existing options,
and see whether (for established SR users) switching/exploring is a good idea,
and (for all new adoption) which framework is best in which situations.

Quirk 1: `./bin/rails hotwire:install` yielded a missing gem: `redis`. Had to
re-run `bundle install` but then all was well.

## Getting Started

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
