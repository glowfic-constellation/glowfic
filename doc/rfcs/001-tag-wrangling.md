# RFC 001: Tag Wrangling Interfaces

**Status:** Draft
**Author:** @l1n
**Created:** 2026-08-03
**Implementation:** glowfic-constellation/glowfic#2877

## 1. Abstract

This document specifies three related additions to the glowfic tag system:

1. A tag graph providing canonical tags, synonyms, and same-type implication,
   together with the roles required to maintain it.
2. Spoiler taggings, which are displayed collapsed and expanded by the reader,
   for elements of the fiction a reader may prefer not to know in advance.
3. Tag suggestions, allowing a reader to propose a tag on a post they do not
   own, with the post author retaining the decision.

The three are specified together because they share one schema change: a
tagging becomes a record carrying state rather than a bare join row.

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

## 3. Prior state

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

Two properties of this implementation constrain the design:

1. **Curation is effectively admin-only.** `Tag#editable_by?` grants rights to
   the tag creator, to holders of `:edit_tags`, and, for unowned `Setting`s, to
   any non-readonly logged-in user. `:edit_tags` and `:delete_tags` are
   commented out of `MOD_PERMS` in `app/concerns/permissible.rb`.
2. **`Tag#merge_with` exists and is correct.** It re-points `UserTag`,
   `PostTag`, `CharacterTag`, `GalleryTag`, and `Tag::SettingTag`,
   de-duplicating as it does so. It has no interface and no concept of which
   tag should survive.

The table behind `Tag::SettingTag` is named `tag_tags` and carries generic
`tag_id` and `tagged_id` columns with no type constraint. Only the model
restricts it to `Setting`. It also carries an unused, nullable `suggested`
boolean.

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
- **`unwrangleable`** distinguishes tags deliberately left alone from tags not
  yet reviewed.
- **Denormalized filters.** `FilterTagging` and `FilterCount` maintain a
  materialized index so that a search for a canonical tag also returns works
  tagged with its synonyms and sub-tags.

AO3 has no general mechanism for suggesting tags on another user's work. Users
add freeform tags to their own works and wranglers canonicalize afterwards.
Section 6.4 therefore has no upstream implementation to follow.

## 5. Problem statement

1. **Duplicate proliferation.** Nothing prevents `Bar Fight`, `Barfight`, and
   `bar-fight` from coexisting as three distinct `Label`s. `citext` collapses
   case only.
2. **No curation interface.** The sole existing tool, `merge_with`, is
   reachable only from a console.
3. **No reader contribution path.** A reader who observes that a post requires
   a tag has no in-application means of saying so.
4. **Tags disclose plot, and readers differ on whether that matters.** A tag
   describes the whole post and is displayed before it, so a tag naming a late
   twist is a disclosure to a reader on reply 3 of 400. Some readers avoid tags
   entirely for this reason; others read tags precisely to decide what to read.
   Authors currently choose between accurate tagging and non-disclosure on
   every reader's behalf.

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
links continue to resolve. Synonyms of the merged tag are re-pointed at the
survivor, keeping chains one level deep. This differs from `merge_with`, which
destroys its argument, so it is a separate method, `merge_as_synonym`. Both
remain available. The interface presents synonyming as the primary action and
destructive merge as an admin-only secondary action, for tags that should never
have existed rather than tags that are duplicates.

**Implication.** `Tag::SettingTag` becomes `Tag::MetaTag` over the same
`tag_tags` table. Both sides of an edge MUST share a `type`; the model enforces
this for any type, so `Label` may gain the hierarchy `Setting` has without a
schema change. The editor exposes hierarchy for `Setting` only.
`Setting`'s existing associations are retained.

Cross-type implication is out of scope. AO3 provides it through
`CommonTagging`, but it raises questions of ownership over the implied tag that
same-type implication does not.

**Unconfirmed implications.** `tag_tags.suggested` is adopted as the
proposed-but-unconfirmed state, and made not null. An edge with
`suggested = true` MUST NOT imply anything at query time. A wrangler scoped to
one Setting will observe implications reaching outside that scope and holds no
authority to assert them. Such an edge is recorded as suggested and is
confirmed or discarded by a holder of `:wrangle_tags_global`. Edges within
scope are created confirmed.

### 6.2 Roles and scoping

Two tiers are defined:

- **`WRANGLER`** — a role holding `:wrangle_tags`, scoped by
  `WranglingAssignment`. May canonicalize, synonym, rename, and re-parent tags
  within assigned Settings and their descendants, and tags sharing a post with
  one of those Settings.
- **Global wrangling** — `:wrangle_tags_global`, held by admins. Covers tags
  belonging to no Setting: `Label`s spanning settings, and all
  `ContentWarning`s. Also the escalation path when a merge crosses two
  assignments.

`:delete_tags`, and therefore destructive merge, remains admin-only.

The two tiers are distinct: global tags have the widest blast radius and MUST
NOT be editable by every holder of a single Setting assignment. The global tier
is nevertheless a capability rather than a third role, because a distinct role
pays for itself only when its membership exceeds the admin group. The
permission is named separately from the role holding it, so promotion to a role
later is a small change.

**Scope.** `WranglingAssignment` joins a user to a `Setting`. A Setting is the
structural analogue of an AO3 fandom, being the world a post is set in, whereas
a Board is a posting venue.

Assignments cascade to descendant Settings automatically. Two properties follow:

- A wrangler responsible for a broad world inherits its sub-worlds without a
  second assignment.
- The scope is itself a wrangled object. Merging two Settings merges the
  assignments onto the survivor, and the wranglers of both MUST be notified.
  Notification rather than approval, because an approval gate would allow one
  wrangler to block another's legitimate merge.

Cascading has two prerequisites:

1. **Cycle rejection.** Scope resolution is a graph traversal and a cycle makes
   a naive traversal non-terminating. Cycle-closing edges, including those that
   would close a cycle only once a suggested edge is confirmed, MUST be
   rejected by model validation rather than recorded and ignored, since a
   silently ignored edge misrepresents the graph. The validation message MUST
   identify the conflicting edge, as ordinary users reach this editor.
   Traversal MUST additionally terminate on cycles, to tolerate rows predating
   the validation; a recursive CTE using `UNION` does so by discarding rows
   already visited.
2. **Hierarchy editing becomes privilege escalation.** With cascading,
   attaching Setting X below Setting Y grants Y's wrangler authority over X.
   Editing `parent_settings` MUST therefore be restricted to users who may
   wrangle the Setting. Editing description remains open as before.

**Queue interface.** `/tag_wranglings`, restricted to wranglers:

- Non-canonical, non-synonym, wrangleable tags within the viewer's scope,
  ordered by usage descending, filterable by type.
- Per-row actions: mark canonical, merge into a canonical tag, mark
  unwrangleable.
- Clusters of names sharing a normalized form, which are both the highest-value
  merges and the least ambiguous decisions.

A denormalized filter index equivalent to AO3's `FilterTagging` is out of
scope. Resolving `merger_id` at query time is sufficient until tag search
becomes a measured bottleneck.

### 6.3 Spoiler taggings

Spoiler state belongs to the tagging, not the tag. A tag naming a twist is not
inherently a disclosure; it is a disclosure on a given post.

The following columns are added to `post_tags`:

| Column | Type | Description |
| --- | --- | --- |
| `spoiler` | boolean, not null, default false | Tagging is collapsed |
| `applies_from_reply_order` | integer, nullable | Reply the tag applies from |

**A spoiler tagging is one the reader must choose to reveal.** It is displayed
collapsed, and expanded on request. The post editor has separate spoiler fields
for Settings and Labels; a tag entered in both a plain and a spoiler field is
kept as a spoiler. Spoiler Settings are not copied onto NPCs created from the
post, as that would disclose them on the character's page.

A tagging is displayed expanded, without the reader acting, when any of:

1. `spoiler` is false.
2. The user is the post author or holds `:edit_posts`.
3. The user has set `users.reveal_spoiler_tags`, default false.

No other condition expands it.

`applies_from_reply_order` is descriptive. It records that a tag applies to the
post from a given reply onwards, and is displayed alongside the tag. This
distinguishes an element that runs through a whole thread from one that appears
late, which flat tagging cannot express. It MAY later anchor a link to that
reply.

**Alternative considered: reveal by reading position.** A tagging could be
expanded automatically once the reader has passed the reply it describes. This
is rejected on three grounds:

1. **It serves nobody.** A reader avoiding disclosure does not read tags; a
   reader who wants warnings does read them. A tag that appears only after the
   material has been read assists neither.
2. **It leaks by omission.** If a tag appears once the reader passes a reply
   and no further tag follows, the reader has learned that nothing else of that
   kind happens in the rest of the post. Withholding a tag until it is redundant
   converts it into a statement about the remainder.
3. **It reads as backwards.** The natural reading of "hidden until you have read
   far enough" is that a warning arrives after the content it warns about.

As a result, nothing in this feature reads `post_views.read_at`.

**`ContentWarning` taggings MUST NOT be spoilered.** A warning exists to tell a
reader about content before they reach it; a warning the reader must first
discover cannot do that. The `spoiler` column therefore applies only to
`Setting` and `Label` taggings, enforced by validation rather than by
convention. Spoilering is for elements of the fiction a reader may or may not
want to know in advance. It is not a mechanism for softening warnings.

**Reverse lookup.** Hiding a tagging on the post page is not sufficient. If a
spoiler tagging participates in tag-to-post listings, the tag page discloses
the post. Three options were considered:

1. Exclude spoiler taggings from reverse lookup entirely. Leak-free. The post
   does not appear under a tag it holds.
2. Filter per viewer. Correct, but makes every tag listing depend on the
   requesting user across every post in the result set, and is therefore
   uncacheable.
3. Include for readers who have set `reveal_spoiler_tags`. A preference is a
   single boolean, so a listing has exactly two variants and both are
   cacheable.

Option 1 is specified, and applies to every reverse lookup: the tag's post
listing, post counts on the tag index, the tag page's description, and post
search by setting. Option 3 MAY follow; exclusion MUST remain the default, and
any cache key for a tag listing MUST then incorporate the preference. The
interface MUST state that marking a tagging as a spoiler removes the post from
that tag's listings, since authors would otherwise assume they retain both
discoverability and non-disclosure.

**Rendering.** The server renders every tagging into the document. Spoiler
taggings not expanded for the viewer are placed inside a collapsed
`%details`/`%summary` element showing a neutral count, the pattern
`posts/show` already uses for author content warnings. This gives
click-to-reveal with no JavaScript.

The consequence MUST be stated plainly to authors: the tag names are present
in the document for every reader, including logged-out ones, and are readable
from source without expanding anything. A spoiler tag hides the tag from the
page as displayed, not from the page as transmitted. This is consistent with
reveal being the reader's choice rather than an access control. Reverse-lookup
exclusion is the part that MUST remain server-side, because a listing that
omits a post cannot be reconstructed by the client.

Changing a post's warnings resets `warnings_hidden` for all viewers
(`Post#reset_warnings`). No equivalent reset applies to spoiler taggings:
re-collapsing a tagging a reader has already seen achieves nothing.

**API.** The API does not currently expose post taggings. If it does, spoiler
taggings not expanded for the requesting user MUST be redacted rather than
omitted:

```json
{ "id": null, "type": "Label", "spoiler": true, "revealed": false }
```

Omission would make the array length misrepresent the post, so a client could
not distinguish "no tags" from "tags withheld". The API's consumer is a
program, so shipping names for the client to hide is meaningless there.

### 6.4 Tag suggestions

A `TagSuggestion` record carries: post, suggester, either an existing tag or a
proposed type and name, status, resolver, resolution timestamp, an optional
note, and the spoiler fields from section 6.3. Exactly one of the existing tag
or the proposed name MUST be present.

**Flow.** A logged-in, non-readonly user proposes a tag on a post they do not
own. The post author is notified, sees pending suggestions, and accepts or
declines them. Acceptance creates the tagging, and creates the tag if proposed,
attributed to the suggester, consistent with `process_tags`.

**Author control.** A per-post `allow_tag_suggestions` flag governs whether a
post accepts suggestions. It defaults, when the post is created, from a
per-user preference of the same name.

**Rejection scope.** A declined tag MUST NOT be suggestible on that post by any
user, not merely by the original suggester. Per-suggester blocking permits an
author to be asked the same question by a succession of readers, which is the
condition that causes authors to disable suggestions entirely. Two
consequences:

- The block is keyed on `(post_id, tag_id)`, or on
  `(post_id, tag_type, tag_name)` for a proposed name, with `tag_name` as
  `citext`. A proposed name matching an existing tag is treated as a
  suggestion of that tag, so re-proposing a declined tag by name does not
  bypass the block.
- Rejection MUST be reversible by the author. A rejection is a standing
  decision, not a permanent one.

**Deduplication and disclosure.** The disclosure risk is not the suggestion but
the deduplication response. "That tag is already on this post" discloses a
collapsed spoiler tagging. "That tag was already declined" discloses the
author's decision. Deduplication MUST therefore fail open: where a collision
exists that the suggester is not entitled to observe, the request returns the
ordinary confirmation and no error.

Where the collision is a tagging collapsed for the suggester, the record is
stored as an **endorsement**: a reader independently proposed a tag already
applied. Endorsements are `TagSuggestion` rows with their own status; they
require no author action and are listed separately. Endorsement is also the
correct presentation for the author, because reporting a redundant suggestion
would invite the author to infer that their spoiler tagging had been disclosed,
which it has not.

Pending suggestions are visible only to the post author. Any future change
surfacing them more widely MUST re-derive these rules and apply the reveal rule
of section 6.3 to the suggestion list.

**Abuse controls.** Readonly and suspended users MUST NOT suggest. Per-user and
per-post caps on pending suggestions apply. A suggestion from a user the post
author has blocked from interacting is discarded, and the suggester receives
the ordinary confirmation, as with a message sent to someone who has blocked
the sender.

**Suggestible types.** Only `Setting`, `Label`, and `ContentWarning` may be
suggested. `GalleryGroup` tags attach to galleries, not posts.

**Content warnings.** Mods MUST NOT apply a `ContentWarning` over an author's
rejection. Authors retain control of their own posts, including of tags they
decline. A reader who believes a post requires a warning the author has
declined has no recourse within the tag system, and must use the existing
out-of-band report, which is a site-rules matter.

## 7. Schema summary

```
tags                   + canonical, unwrangleable, merger_id
tag_tags               suggested made not null
wrangling_assignments  new (user_id, setting_id)
post_tags              + spoiler, applies_from_reply_order
posts                  + allow_tag_suggestions
users                  + allow_tag_suggestions, reveal_spoiler_tags
tag_suggestions        new
```

## 8. Rollout

1. Tag graph columns and model constraints, without interface. No backfill;
   every tag begins non-canonical. Viable only under the invariant in
   section 6.1. Cycle validation and the restriction of `parent_settings`
   editing ship here, ahead of the role work they unblock.
2. Wrangler role and queue interface.
3. Spoiler taggings, with the reveal preference.
4. Suggestions, once a wrangler group exists to absorb the resulting moderation
   load.

Because the queue initially contains the entire corpus, it MUST be ordered by
value rather than presented as a list to be completed:

- Default ordering by usage count descending.
- Clustering of near-identical names under a normalization covering case,
  whitespace, punctuation, and simple pluralization. Computed and cached rather
  than stored, so the normalization can be adjusted without a migration.
- Progress reported as coverage weighted by usage, not as a count of remaining
  tags. The remaining count will not move perceptibly for a long period.

Not part of the initial implementation:

- An interface for proposing and confirming suggested implications.
- A hierarchy editor for `Label`.
- Surfacing declined `ContentWarning` suggestions to mods as a signal.

## 9. Resolved decisions

1. `Tag::SettingTag` becomes `Tag::MetaTag`, permitting same-type hierarchy for
   any type. Cross-type implication deferred.
2. Wrangling assignments scope by `Setting`, not by `Board`.
3. Global wrangling is an admin capability, not a third role, while remaining a
   distinct tier.
4. No canonical backfill. Canonicalization is manual, under the invariant that
   `canonical` gates nothing.
5. Merging produces synonyms by default. Destructive merge is retained,
   admin-only.
6. Assignments inherit down the Setting hierarchy automatically.
7. Assignments follow a merged Setting and notify the wranglers of both. No
   approval gate.
8. Cycle-closing edges are rejected by validation.
9. Duplicate clustering is computed and cached, not stored.
10. Reveal is a reader action. Reading position plays no part.
11. Readers get a `reveal_spoiler_tags` preference, and any reader may expand a
    collapsed tagging.
12. Spoiler taggings are excluded from every reverse lookup.
13. `ContentWarning` taggings cannot be spoilered, enforced by validation.
14. A rejected suggestion blocks that tag on that post for all users, and is
    reversible by the author.
15. Spoiler taggings are suggestible. Deduplication fails open.
16. A suggestion colliding with a tagging collapsed for the suggester is stored
    as an endorsement, a `TagSuggestion` status.
17. Mods cannot override an author's rejection of a `ContentWarning`.

## 10. Open items

**Should a reader be able to see that a post has spoiler tags at all?** The
collapsed control necessarily discloses that some number of tags exist and are
collapsed. For a sufficiently disclosure-averse reader that count is itself
information, and a preference to suppress the control entirely may be wanted
alongside the preference to expand it. Not specified here because it is not
clear the demand exists.
