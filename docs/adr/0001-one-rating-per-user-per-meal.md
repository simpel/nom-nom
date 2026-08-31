---
status: accepted
---

# One rating per user per meal, with party-gated visibility

A meal can be served to several dinner parties at once, and a member of one party
must not see ratings from members of another. The obvious way to express that is to
scope the rating row itself — `meal_ratings.party_id`, one verdict per person per
party — and that is where we started, on the reasoning that different occasions
call for different taste preferences. We rejected it: a person has one opinion of
one plate of food, and asking them to record it twice produces two rows that can
disagree about the same fact. Instead a rating is unique on `(meal_id, rater_id)`
and carries no party, and the party rule is *computed* — a rating counts for a
party when its rater is a member of that party and the meal was served to that
party.

## Consequences

- Two parties reach different conclusions about the same dish through **different
  membership**, not through duplicate rows. The ranking already supports this: it
  derives a score per person per dish, so scoping is a filter on which people count.
- Rating visibility cannot be a column comparison. It is a join across
  `party_members` and `meal_parties`, which is why RLS needs a `SECURITY DEFINER`
  helper rather than an inline predicate.
- The rating rows *are* a user's long-term taste history, already portable across
  parties by construction. Nothing further is needed in the schema if we later want
  a cross-party taste profile — only a way to aggregate it without exposing the
  underlying rows.
- If two occasions genuinely deserve different verdicts, they are two **meals**,
  each with its own date and its own ratings — not one meal rated twice.
