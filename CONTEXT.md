# Context

The domain language of Nom Nom. A glossary and nothing else — no implementation
detail, no plans. If a term here disagrees with the code, one of the two is wrong
and it is worth finding out which.

## Party

Short for **dinner party**: a named, lasting set of users who eat together. A user
belongs to any number of parties — a lunch party and a dinner party are different
parties with different members.

A party is **flat**: every member is equal. Any member may invite, any member may
remove any member, and a member may always leave. There is no host, owner or
admin. The party closes when its last member leaves.

Parties are additive, not required. A user in no party still logs meals, rates them
and gets suggestions — see [Just me](#just-me).

## Member

A user who belongs to a party. Membership is the only grant of access: being a
member is what lets you see the party's meals and its members' ratings.

Every participant in Nom Nom is a real user with an account. There is no such thing
as a participant without one — no "eater", no name-only person, no child tracked by
somebody else.

## Invite

An offer of membership in a party, addressed to an **email address** rather than to
a user. An invite whose address has no account yet is **unclaimed**: it waits, and
is claimed automatically if that address ever signs up.

Accepting an invite grants access to the party's **entire** meal history, not only
what happens afterwards.

## Meal

One occasion of eating a dish, logged by one user on one date. A meal is **served
to** any number of parties, including none. Serving a meal to a party is what makes
it visible to that party's members — there is no separate per-meal invitation.

A meal served to no party is private to the user who logged it.

## Dish

The canonical name of something cooked. A dish belongs to the user who created it —
it is a personal catalogue, not a party's. The same dish is served to any party.

## Rating

One user's verdict on one meal: **loved**, **ok**, or **not a fan**. Exactly one
rating per user per meal — a person has one opinion of one plate of food. A rating
carries no party.

Which ratings you can *see*, and which the ranking counts, is decided by party
membership rather than by the rating itself: a rating counts for a party when its
rater is a member of that party and the meal was served to that party. Two parties
therefore reach different verdicts on the same dish through different membership,
not through duplicate rows. See [ADR 0001](docs/adr/0001-one-rating-per-user-per-meal.md).

Leaving a rating blank means "didn't catch it". It is ignored by the ranking, never
counted as a bad score.

## Context

What the app is currently scoped to: either **Just me** or one party. The context
decides whose ratings are visible and what "what to eat" ranks over. It is chosen
from a single menu in the navigation bar and applies across the app.

### Just me

The personal context. Your own meals and your own ratings, with no party involved.

## Taste profile

A user's preferences accumulated across every rating they have ever made, in any
party. Today this exists only implicitly, as the per-person scores the ranking
derives within a single context. A portable, cross-party profile that one party can
consume from another is a **later** effort and deliberately not part of the current
model.
