# RFC 001: Tag Wrangling Interfaces

**Status:** Draft
**Author:** @l1n
**Created:** 2026-08-03
**Implementation:** glowfic-constellation/glowfic#2877

## 1. Abstract

This document specifies three related additions to the glowfic tag system:

1. A tag graph providing canonical tags, synonyms, and same-type implication,
   together with the roles required to maintain it.
2. Tag suggestions, allowing a reader to propose a tag on a post they do not
   own, with the post author retaining the decision.
3. Spoiler taggings, which are displayed collapsed and expanded by the reader,
   for elements of the fiction a reader may prefer not to know in advance.

The three are specified together because they share one schema change: a
tagging must become a record carrying state rather than a bare join row.

## 2. Terminology

The key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
to be interpreted as described in RFC 2119.

- **Tag** — a row in `tags`, of type `Setting`, `Label`, `ContentWarning`, or
  `GalleryGroup`.
- **Tagging** — the association of a tag with a post; a row in `post_tags`.
- **Canonical tag** — a tag a wrangler has reviewed and accepted as the
  preferred form.
- **Synonym** — a non-canonical tag pointing at the canonical tag that
  supersedes it.
- **Implication** — a directed edge asserting that tagging the child implies
  the parent.
- **Wrangler** — a user holding curation rights over some set of tags.

## 3. Current implementation

Tags are single-table inheritance over `tags`:

- `Tag::TYPES` is `Setting`, `Label`, `ContentWarning`, `GalleryGroup`.
- `tags.name` is `citext`, unique per `type`. Case variants are already
  collapsed within a type.
- Every tag has a non-null `user_id` and an `owned` boolean used by `Setting`.
- Only `Setting` has hierarchy, through `Tag::SettingTag`.

Tags reach posts through `Taggable#process_tags`. The form submits existing tag
IDs alongside new names prefixed with `_`. The concern resolves the former,
case-insensitively matches the latter against existing tags, and constructs new
records for the remainder. Creating a site-wide tag therefore requires no
permission beyond the ability to edit the post being tagged.

Two properties of the current implementation constrain the design:

1. **Curation is effectively admin-only.** `Tag#editable_by?` grants rights to
   the tag creator, to holders of `:edit_tags`, and, for unowned `Setting`s, to
   any non-readonly logged-in user. `:edit_tags` and `:delete_tags` are
   commented out of `MOD_PERMS` in `app/concerns/permissible.rb:17-18`.
2. **`Tag#merge_with` exists and is correct.** It re-points `UserTag`,
   `PostTag`, `CharacterTag`, `GalleryTag`, and `Tag::SettingTag`,
   de-duplicating as it does so. It has no interface and no concept of which
   tag should survive.

The table behind `Tag::SettingTag` is named `tag_tags` and carries generic
`tag_id` and `tagged_id` columns with no type constraint. Only the model
restricts it to `Setting`. It also carries an unused `suggested` boolean.

Reading position is already recorded. `post_views` carries `read_at` and
`warnings_hidden`; `Post#show_warnings_for?` gates the content-warning
interstitial per user; `Post#hide_warnings_for` records dismissal; and changing
a post's warnings resets `warnings_hidden` for all viewers
(`app/models/post.rb:364`). `Post#last_seen_reply_for` maps a `read_at`
timestamp onto a reply, and `replies.reply_order` orders replies within a post.

## 4. Prior art

Relevant mechanisms in `otwcode/otwarchive`:

- **Canonical and merger.** `tags.canonical` is a boolean. A non-canonical tag
  points at its canonical form through `merger_id`. Synonymy is a pointer, not
  a table.
- **Two hierarchies.** `MetaTagging` expresses implication between tags of the
  same kind. `CommonTagging` expresses cross-type containment, such as a
  Character belonging to a Fandom.
- **Assigned wrangling.** `WranglingAssignment` joins a user to a fandom, so
  wranglers hold bounded scopes rather than the whole namespace.
  `WranglingGuideline` publishes policy in-application.
  `LastWranglingActivity` records staleness.
- **`unwrangleable`** distinguishes tags deliberately left alone from tags not
  yet reviewed.
- **Denormalized filters.** `FilterTagging` and `FilterCount` maintain a
  materialized index so that a search for a canonical tag also returns works
  tagged with its synonyms and sub-tags.

AO3 has no general mechanism for suggesting tags on another user's work. Users
add freeform tags to their own works and wranglers canonicalize afterwards. The
`*_nomination` models belong to tag sets and challenges. Section 6.4 therefore
has no upstream implementation to follow.

## 5. Problem statement

1. **Duplicate proliferation.** Nothing prevents `Bar Fight`, `Barfight`, and
   `bar-fight` from coexisting as three distinct `Label`s. `citext` collapses
   case only.
2. **No curation interface.** The sole existing tool, `merge_with`, is
   reachable only from a console.
3. **No reader contribution path.** A reader who observes that a post requires
   a content warning has no in-application means of saying so.
4. **Tags disclose plot, and readers differ on whether that matters.** A tag
   describes the whole post and is displayed before it, so `Character Death` is
   a disclosure to a reader on reply 3 of 400. Some readers avoid tags entirely
   for this reason; others read tags precisely to decide what to read, and
   regard the journey rather than the surprise as the point. Authors currently
   choose between accurate tagging and non-disclosure on every reader's behalf.

## 6. Design

### 6.1 Tag graph

The following columns are added to `tags`:

| Column | Type | Description |
| --- | --- | --- |
| `canonical` | boolean, not null, default false | Reviewed and accepted form |
| `merger_id` | integer, nullable, FK to `tags.id` | Synonym pointer |
| `unwrangleable` | boolean, not null, default false | Deliberately skipped |

The following constraints MUST hold:

- A tag with `merger_id` set MUST NOT be canonical.
- `merger_id` MUST reference a tag of the same `type`.
- A merger MUST itself be canonical. Synonym chains are therefore one level
  deep and resolve in a single join.

**Invariant: `canonical` MUST NOT gate behaviour.** Search, filtering,
autocomplete, and display MUST treat canonical and non-canonical tags
identically. `canonical` records that a human has reviewed the tag. `merger_id`
is the only column that alters behaviour, and it is set only by an explicit
merge.

This invariant is what makes the rollout in section 8 viable. No backfill is
performed, so every tag begins non-canonical and the queue initially contains
the entire corpus. That is a backlog rather than a defect only for as long as
the invariant holds. Any proposal to gate behaviour on `canonical` MUST revisit
this decision first.

**Merging.** Synonyming is the default outcome: the merge re-points every
tagging onto the surviving tag and sets `merger_id` on the other, so existing
links continue to resolve. This is a change to the contract of `merge_with`,
which destroys its argument, so it is introduced as a separate method. Both
remain available. The interface SHOULD present synonyming as the primary action
and destructive merge as an admin-only secondary action, for tags that should
never have existed rather than tags that are duplicates.

**Implication.** `Tag::SettingTag` becomes `Tag::MetaTag` over the same
`tag_tags` table, and `Label` gains the hierarchy `Setting` has. Both sides of
an edge MUST share a `type`. No migration is required; `Setting`'s existing
associations are retained as named wrappers.

Cross-type implication is out of scope. AO3 provides it through
`CommonTagging`, but it raises questions of ownership over the implied tag that
same-type implication does not.

**Unconfirmed implications.** `tag_tags.suggested` is adopted as the
proposed-but-unconfirmed state. An edge with `suggested = true` MUST NOT imply
anything at query time and MUST appear in a confirmation queue. A wrangler
scoped to one Setting will observe implications reaching outside that scope,
most commonly that a Setting implies a ContentWarning, and holds no authority to
assert them. Such an edge is recorded as suggested and is confirmed or discarded
by a holder of `:wrangle_tags_global`. Edges within scope are created confirmed.

### 6.2 Roles and scoping

Two tiers are defined:

- **`WRANGLER`** — a role holding `:wrangle_tags`, scoped by
  `WranglingAssignment`. May canonicalize, synonym, and edit tags within
  assigned Settings and their descendants.
- **Global wrangling** — `:wrangle_tags_global` and unscoped `:edit_tags`,
  held by admins. Covers tags belonging to no Setting: `Label`s spanning
  settings, and all `ContentWarning`s. Also the escalation path when a merge
  crosses two assignments.

`:delete_tags` remains admin-only in both tiers.

The two tiers are distinct: global tags have the widest blast radius and MUST
NOT be editable by every holder of a single Setting assignment. The global tier
is nevertheless a capability rather than a third role, because a distinct role
pays for itself only when its membership exceeds the admin group. The permission
is named separately from the role holding it, so promotion to a role later is a
small change.

**Scope.** `WranglingAssignment` joins a user to a `Setting`. A Setting is the
structural analogue of an AO3 fandom, being the world a post is set in, whereas
a Board is a posting venue.

Assignments cascade to descendant Settings automatically. Two properties follow:

- A wrangler responsible for a broad world inherits its sub-worlds without a
  second assignment.
- The scope is itself a wrangled object. Merging two Settings merges the
  assignments onto the survivor, and both wranglers MUST be notified.
  Notification rather than approval, because an approval gate would allow one
  wrangler to block another's legitimate merge.

Cascading has two prerequisites, both blocking:

1. **Cycle rejection.** `tag_tags` has no cycle guard. Scope resolution is a
   graph traversal and a cycle makes it non-terminating. Cycle-closing edges
   MUST be rejected by model validation rather than recorded and ignored, since
   a silently ignored edge misrepresents the graph. Traversal SHOULD
   additionally use a cycle-detecting recursive CTE, to tolerate rows predating
   the validation. Rejection changes the behaviour of an editor ordinary users
   reach, so the validation message MUST identify the conflicting edge.
2. **Hierarchy editing becomes privilege escalation.** With cascading,
   attaching Setting X below Setting Y grants Y's wrangler authority over X.
   `Tag#editable_by?` currently permits any non-readonly logged-in user to edit
   an unowned `Setting`, and `tags_controller#update` assigns `parent_settings`
   directly. Editing `parent_settings` MUST therefore be restricted to
   wranglers. Editing name and description MAY remain open.

**Queue interface.** `/tags/wrangling`, restricted to wranglers:

- Non-canonical, non-synonym tags, ordered by usage descending, filterable by
  type.
- Per-row actions: mark canonical, merge into a canonical tag, mark
  unwrangleable.
- Clusters of names sharing a normalized form, which are both the highest-value
  merges and the least ambiguous decisions.

A denormalized filter index equivalent to AO3's `FilterTagging` is out of
scope. Resolving `merger_id` at query time is sufficient until tag search
becomes a measured bottleneck.

### 6.3 Spoiler taggings

Spoiler state belongs to the tagging, not the tag. `Character Death` is not
inherently a disclosure; it is a disclosure on a given post until a given reply.

The following columns are added to `post_tags`:

| Column | Type | Description |
| --- | --- | --- |
| `spoiler` | boolean, not null, default false | Tagging is withheld |
| `reveal_after_reply_order` | integer, nullable | Reveal threshold |

**A spoiler tagging is one the reader must proactively reveal.** It is displayed
collapsed, and expanded on request. Reveal is a reader action, not a state the
server computes from how far they have read.

An earlier draft of this document gated reveal on reading position, so that a
tagging became visible once the reader passed the reply it described. Reader
feedback rejected that model on three grounds, all of which stand:

1. **It serves nobody.** A reader avoiding disclosure does not read tags; a
   reader who wants warnings does read them. A tag that appears only after the
   material has been read assists neither.
2. **It leaks by omission.** Auto-revealing after the fact tells the reader
   something the author did not choose to tell them. If `Character Death`
   appears once and no further tag follows, the reader has learned that the
   death they just read was the only one. Withholding a tag until it is
   redundant does not merely fail to protect; it converts the tag into a
   statement about the rest of the post.
3. **It reads as backwards.** The natural reading of "hidden until you have read
   far enough" is that a warning arrives after the content it warns about.

`reveal_after_reply_order` is retained, but its meaning changes: it is
**descriptive, not a gate**. It records that a tag applies to the post from a
given reply onwards, and is displayed alongside the tag once revealed. This is
the part of the original design readers found valuable, because it distinguishes
a element that runs through a whole thread from one that appears late, which is
a distinction flat tagging cannot express. It also gives a natural anchor for
linking a reader to the point where the tag begins to apply.

A tagging is displayed expanded, without the reader acting, when any of:

1. The user is the post author or holds `:edit_posts`.
2. `spoiler` is false.
3. The user has set the preference in section 6.5.

No other condition expands it. In particular, reading position does not.

**`ContentWarning` taggings MUST NOT be spoilered.** A warning exists to tell a
reader about content before they reach it; a warning the reader must first
discover cannot do that, and one revealed after the fact has failed entirely.
There is no way to have content warnings without warning people about the
content. The `spoiler` column therefore applies only to `Setting` and `Label`
taggings, enforced by validation rather than by convention.

This also disposes of the sharpest objection to the feature. Spoilering is for
elements of the fiction a reader may or may not want to know in advance. It is
not a mechanism for softening warnings, and must not become one.

**Reverse lookup.** Hiding a tagging on the post page is not sufficient. If a
spoiler tagging participates in tag-to-post listings, the tag page discloses the
post. Three options were considered:

1. Exclude spoiler taggings from reverse lookup entirely. Leak-free. The post
   does not appear under a tag it holds.
2. Filter per viewer. Correct, but makes every tag listing depend on the
   requesting user's read state across every post in the result set, and is
   therefore uncacheable.
3. Include behind an explicit opt-in preference, defaulting to off.

Option 1 is specified. Option 2 is rejected on cost. Option 3 MAY follow. The
interface MUST state that marking a tagging as a spoiler removes the post from
that tag's listings, since authors would otherwise assume they retain both
discoverability and non-disclosure.

**Presentation.** The reveal interface SHOULD follow the existing content
warning pattern rather than introduce a second one: a neutral count of withheld
taggings, expandable on request. Note that changing a post's warnings resets
`warnings_hidden` for all viewers (`app/models/post.rb:364`); the equivalent
reset for spoiler taggings is not wanted, as re-hiding a tagging a reader has
already seen achieves nothing.

Because the count is expandable by any reader, the reading-position gate is a
default rather than an enforcement boundary. Section 6.5 makes this explicit
rather than leaving it as an artefact of the presentation.

**API.** `apipie` exposes post tags, so the reveal rule MUST apply there.
Unrevealed taggings are redacted rather than omitted:

```json
{ "id": null, "type": "Label", "spoiler": true, "revealed": false }
```

Omission would make the array length misrepresent the post, so a client could
not distinguish "no tags" from "tags withheld", and any client computing counts
would be silently wrong. Authenticated requests resolve `revealed` against the
requesting user. Anonymous requests hold no read state and receive every spoiler
tagging redacted.

### 6.4 Tag suggestions

A `TagSuggestion` record carries: post, suggester, either an existing tag or a
proposed type and name, status, resolver, resolution timestamp, an optional
note, and the spoiler fields from section 6.3. Exactly one of the existing tag
or the proposed name MUST be present.

**Flow.** A logged-in, non-readonly user proposes a tag on a post they do not
own. The post author sees pending suggestions and accepts or declines them.
Acceptance creates the tagging, and creates the tag if proposed, attributed to
the suggester, consistent with `process_tags`.

**Author control.** A per-post `allow_tag_suggestions` flag and a per-user
default govern whether a post accepts suggestions.

**Rejection scope.** A declined tag MUST NOT be suggestible on that post by any
user, not merely by the original suggester. Per-suggester blocking permits an
author to be asked the same question by a succession of readers, which is the
condition that causes authors to disable suggestions entirely. Two consequences:

- The block is keyed on `(post_id, tag_id)`, or on
  `(post_id, tag_type, lower(tag_name))` for a proposed name, so that
  re-proposing a declined tag as a new name does not bypass it. `citext` covers
  existing tags; proposed names require explicit comparison, as no `Tag` row
  exists.
- Rejection MUST be reversible by the author. A rejection is a standing
  decision, not a permanent one.

**Deduplication and disclosure.** The disclosure risk is not the suggestion but
the deduplication response. "That tag is already on this post" discloses a
withheld spoiler tagging. "That tag was already declined" discloses the author's
decision. Deduplication MUST therefore be read-state aware and MUST fail open:
where a collision exists that the suggester is not entitled to observe, the
request returns the ordinary confirmation and no error.

Where the collision is a tagging the suggester cannot see, the record is stored
as an **endorsement**: a reader independently proposed a tag already applied.
Endorsements require no author action and accumulate against the tagging.
Endorsement is also the correct presentation for the author, because reporting a
redundant suggestion would invite the author to infer that their spoiler tagging
had been disclosed, which it has not.

Pending suggestions are visible only to the post author. Any future change
surfacing them more widely MUST re-derive these rules and apply the reveal rule
of section 6.3 to the suggestion list.

**Abuse controls.** Readonly and suspended users MUST NOT suggest. Per-user and
per-post caps on pending suggestions apply. Existing ignore lists suppress
suggestions from ignored users.

**Suggestible types.** Only `Setting`, `Label`, and `ContentWarning` may be
suggested. `GalleryGroup` tags attach to galleries, not posts, and a tagging
referencing one would be surfaced by none of `Post#settings`, `#labels`, or
`#content_warnings`.

**Content warnings.** Mods MUST NOT apply a `ContentWarning` over an author's
rejection. Authors retain control of their own posts, including of tags they
decline. The consequence is stated explicitly: a reader who believes a post
requires a warning the author has declined has no recourse within the tag
system, and must use the existing out-of-band report, which is a site-rules
matter. A declined `ContentWarning` suggestion MAY be surfaced to mods as a
signal without conferring authority to act on it.

### 6.5 Reader-controlled reveal

Deferred: not required for the initial implementation, specified here because it
changes one cost assessment in section 6.3 and should not be designed twice.

Reader tolerance for disclosure varies widely, from readers who want to know
nothing about a story in advance to readers who treat tags as advertising and
prefer to be told everything. Section 6.3 gates reveal on reading position
alone, which encodes a single policy for every reader. The intent of marking a
tagging as a spoiler is to describe *when* the tagged material arrives, not to
decide on the reader's behalf whether they want to know.

Two mechanisms are specified, and they compose:

1. **Preference.** `users.reveal_spoiler_tags`, default false. When true,
   spoiler taggings are revealed to that user regardless of reading position.
2. **Click to reveal.** An unrevealed tagging renders as a count that any
   reader MAY expand, whatever their preference. Persistence MAY follow the
   `warnings_hidden` pattern, or MAY be per-request; the choice does not affect
   the rest of this section.

**Effect on reverse lookup.** This is the substantive consequence. Section 6.3
rejects per-viewer filtering because it makes a tag listing depend on the
requesting user's read state across every post in the result set, which is
uncacheable. A preference does not have that shape: it is a single boolean on
the user, so a listing has exactly two variants and both are cacheable. Option 3
of section 6.3 therefore becomes affordable once the preference exists.

Accordingly, when `reveal_spoiler_tags` is set, spoilered taggings MAY
participate in tag-to-post listings for that user. Exclusion MUST remain the
default, and any cache key for a tag listing MUST incorporate the preference.

**Effect on the position gate.** Once a reader can expand the count or set the
preference, reading position is a convenience that reveals tags automatically at
the point they stop being disclosures. It is not an access control, and MUST NOT
be described as one to authors. Authors mark *when*; readers choose *whether*.

**Rendering.** Reveal SHOULD be resolved on the client rather than by omitting
markup on the server. The server renders every tagging into the document, with
spoilered ones inside a collapsed disclosure element; the reader's preference
sets whether it starts open.

This follows a pattern the codebase already uses. `app/views/posts/show.haml:35`
wraps author content warnings in `%details`/`%summary`, which gives
click-to-reveal with no JavaScript at all. Building on it means the feature
degrades correctly: with scripting unavailable the tags are still collapsed and
still expandable. JavaScript is then needed only to apply the stored preference
without a round trip, and `gon` already carries per-user state to the client
(`app/controllers/application_controller.rb:213`).

The benefit is that the tag markup stops varying per reader. Reveal becomes
presentational, so it does not enter any fragment cache key, and rendering a
post no longer needs the reader's position resolved before the tags can be
emitted.

**The tradeoff MUST be stated plainly to authors, because it is a real one.**
Rendering server-side and omitting withheld tags means the tag names are absent
from the page. Rendering client-side means the names are present in the document
for every reader, including logged-out ones, and are readable from source or
developer tools without expanding anything. This is consistent with the position
taken above, that the gate is a default and not an access boundary, but it is a
stronger claim than the initial implementation makes, and adopting it is a
visible change in what a spoiler tag guarantees. Authors MUST be told that a
spoiler tag hides the tag from the page as displayed, not from the page as
transmitted.

Two things MUST remain server-side regardless, because the client cannot
enforce them:

1. Reverse-lookup exclusion. A listing that omits a post cannot be reconstructed
   client-side, and this is the mechanism that keeps a tag page from disclosing
   the post.
2. API redaction, per section 6.3. The API's consumer is a program, and shipping
   names for the client to hide is meaningless there.

**No dependency on reading position.** Because reveal is a reader action,
nothing in this feature reads `post_views.read_at`. Removing that dependency
also removes the timestamp limitation an earlier draft carried, whereby a reader
who opened a post while it was short and returned much later resolved to a
reading position they had not actually reached.

**Skip links.** Since `reveal_after_reply_order` is descriptive, a revealed
tagging carries a usable anchor: the reply from which the tag applies. Linking
it lets a reader jump to the point where an element enters the post. This is
cheap once the datum is displayed rather than consumed as a gate, and is worth
building at the same time.

## 7. Schema summary

```
tags                   + canonical, unwrangleable, merger_id
post_tags              + spoiler, reveal_after_reply_order
posts                  + allow_tag_suggestions
users                  + allow_tag_suggestions
tag_suggestions        new
wrangling_assignments  new (user_id, setting_id)
tag_tags               unchanged; `suggested` adopted per section 6.1

deferred, section 6.5:
users                  + reveal_spoiler_tags
```

`post_tags` is currently a bare join table and several queries treat it as one.
Those queries MUST be audited before the migration.

`tag_tags.suggested` defaults to false and no rows set it, so existing edges are
correctly interpreted as confirmed without a data migration.

## 8. Rollout

1. Tag graph columns and model constraints, without interface. No backfill;
   every tag begins non-canonical. Viable only under the invariant in
   section 6.1.
2. Wrangler role and queue interface.
3. Spoiler taggings. Self-contained and the most immediately useful to authors.
4. Suggestions, once a wrangler group exists to absorb the resulting moderation
   load.
5. Reader-controlled reveal, per section 6.5: the `reveal_spoiler_tags`
   preference and client-side expansion. Step 3 is of limited use without it,
   since expansion is the only way a reader sees a spoiler tagging at all.

The two prerequisites in section 6.2, cycle validation and restriction of
`parent_settings` editing, SHOULD be implemented ahead of step 2. Both are
small, independently useful, and block the role work.

Because the queue initially contains the entire corpus, it MUST be ordered by
value rather than presented as a list to be completed:

- Default ordering by usage count descending.
- Clustering of near-identical names under a normalization covering case,
  whitespace, punctuation, and simple pluralization. Computed and cached rather
  than stored, so the normalization can be adjusted without a migration.
  Invalidated on tag creation, rename, and merge.
- Progress reported as coverage weighted by usage, not as a count of remaining
  tags. The remaining count will not move perceptibly for a long period.

## 9. Resolved decisions

1. `Label` gains hierarchy. `Tag::SettingTag` becomes `Tag::MetaTag`; no
   migration. Cross-type implication deferred.
2. Wrangling assignments scope by `Setting`, not by `Board`.
3. Global wrangling is an admin capability, not a third role, while remaining a
   distinct tier.
4. No canonical backfill. Canonicalization is manual, under the invariant that
   `canonical` gates nothing.
5. Merging produces synonyms by default. Destructive merge is retained,
   admin-only.
6. Assignments inherit down the Setting hierarchy automatically, conditional on
   the two prerequisites in section 6.2.
7. Assignments follow a merged Setting and notify both wranglers. No approval
   gate.
8. Cycle-closing edges are rejected by validation.
9. Duplicate clustering is computed and cached, not stored.
10. The API redacts withheld spoiler taggings rather than omitting them.
11. A rejected suggestion blocks that tag on that post for all users, and is
    reversible by the author.
12. Spoiler taggings are suggestible. Deduplication is read-state aware and
    fails open.
13. A suggestion colliding with a tagging the suggester cannot observe is
    recorded as an endorsement.
14. Mods cannot override an author's rejection of a `ContentWarning`.
15. Readers get a `reveal_spoiler_tags` preference, and any reader may expand a
    withheld tagging.
16. Reveal is resolved on the client, using the `%details`/`%summary` pattern
    already used for content warnings, so it degrades without JavaScript and
    does not vary the markup per reader. Reverse-lookup exclusion and API
    redaction remain server-side.
17. Reveal is a reader action. Reading position does not expand a tagging, and
    the feature reads no reading state at all. Revised after reader feedback;
    see section 6.3.
18. `reveal_after_reply_order` is descriptive rather than a gate: it records the
    reply from which a tag applies, is shown once the tag is revealed, and
    anchors a skip link.
19. `ContentWarning` taggings cannot be spoilered, enforced by validation.

## 10. Open items

**Should a reader be able to see that a post has spoiler tags at all?** The
collapsed control necessarily discloses that some number of tags exist and are
withheld. For a sufficiently disclosure-averse reader that count is itself
information, and a preference to suppress the control entirely may be wanted
alongside the preference to expand it. Not specified here because it is not
clear the demand exists.

Endorsements require a schema decision at implementation time. They are close
enough to `TagSuggestion` to reuse it with an additional status, and different
enough, in carrying no pending decision and being of aggregate rather than
individual interest, that a counter on `post_tags` may be preferable. The
decision SHOULD be made against the queries the author's view requires.
