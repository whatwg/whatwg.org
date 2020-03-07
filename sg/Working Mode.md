# WHATWG Working Mode

The WHATWG develops standards and assists in maintaining their corresponding tests, thereby fostering independent implementations. The WHATWG adheres to a shared [Code of Conduct](./Code%20of%20Conduct.md).

While discussing and working on standards, it’s always useful to keep these questions in mind:

* What do implementations do?
* What do the tests reveal?
* What should the processing model look like?

## Standard

Each standard (ideally) has:

* An active community of contributors.
* An assigned editor and zero or more deputy editors.
* A changelog. (A tidy Git repository with linear history.)
* An issue tracker.
* Corresponding tests.

### Editor

The editor has the following responsibilities, all of which can be delegated to deputy editors:

* Ensure any applied changes fulfill the relevant criteria for changes.
* Resolve conflicts between contributors.
* Reduce open issues.
* Help manage the corresponding tests.
* Ensure implementations follow the standard and vice versa. (The “don’t write fiction” rule.)

## Issues

### Normative issues

Problems with the standard are generally recorded as issues. Resolving an issue typically involves answering these questions:

* What do implementations do?
* What is the ideal behavior?
* What is the lowest cost towards convergence? (Counting lowest number of implementations that would have to change as the cheapest solution.)
* What do implementations want to do?

It’s not always possible to get the answers to all these questions in a timely manner. Therefore, it might be the case that a decision is made even without input from all parties. This makes it very important to file bugs for any spec changes (as discussed below), as a final check to make sure all implementers are on board with, or at least aware of, the change.

Additions to the standard can also be proposed as issues. However, the process for turning such an issue into an accepted change to the standard is generally more involved, as the criteria for additions is stricter (see [Additions](#additions)). A typical path for turning such issues into accepted changes is detailed in the [New Proposals](#new-proposals) section.

### Non-normative issues

Changes of editorial nature can be made, accepted, or rejected by the editor without discussion.

## Changes

Each normative change made to the standard needs to meet the following criteria:

* It must have support from implementers.
* It should have corresponding test changes, either in the form of new tests or modifications to existing tests.
* Implementations bugs must be filed for each user agent that fails tests. (This is each user agent that doesn’t match the proposed changes. If the test changes are not adequate to reveal that, but it’s known through other means, the tests should be improved first.)
* It should have been reviewed by one or more members of the community.
* Optional or implementation-defined behavior must be very well motivated.

Additionally, the following more mechanical criteria are used to hone a change before accepting it:

* It should match the standard’s source formatting and style conventions. (Consistent formatting helps new contributors know what to do.)
* It must have a good commit message, with at the minimum a title, but typically with a body that includes pointers to relevant discussion, tests changes, and a more elaborate description of the change. (A detailed commit message helps folks in the future figure out why a decision was made. This happens a lot more than you might imagine.)

NOTE: If the change is proposed by a new contributor, the editor can ensure the commit message is good, and help with formatting and style. There’s no need to make new contributors jump through too many hoops.

### Additions

Any change that represents an addition needs to meet these additional criteria:

* The addition must have the support of at least two implementers. (Such support is not binding in any way on the implementers, however.)

Additionally, the following are strongly recommended:

* The support from implementers should be of the form “we would like to implement this soon” and not just “this seems like a reasonable idea”.
* There should be no strong implementer objections to the new feature.
* There should already be a prototype implementation or one being worked on side-by-side with the change to the standard.
* New features should be something that cannot be done today or are such a common trend in libraries that standardizing them helps lots of people. Alternatively, the “new” feature could actually be a legacy feature that was not yet standardized, which is now being standardized. (Legacy features are often hard to remove due to web compatibility; standardizing and testing them helps improve interoperability and enables competition and refactoring.)

### Removals

Any change that represents a removal needs to meet these additional criteria:

* The feature being removed must either be not widely implemented, or must in the process of being removed from implementations.

* A test ensuring the feature is not supported must be added and existing tests for the feature should be adjusted or removed as appropriate.

  EXAMPLE: [w3c/web-platform-tests#5001](https://github.com/w3c/web-platform-tests/pull/5001) added new tests that appcache was not supported in shared workers, per the removal in [whatwg/html#2384](https://github.com/whatwg/html/pull/2384).

  EXAMPLE: Adjusting existing tests can be difficult. If necessary, an issue can be filed instead to track updating those tests. This was done in [w3c/web-platform-tests#5053](https://github.com/w3c/web-platform-tests/issues/5053) which accompanied the removal in [whatwg/html#2402](https://github.com/whatwg/html/pull/2402).

### New proposals

As described above, the criteria for inclusion in a WHATWG standard is rather strict. In the initial stages of feature development for the web platform, such widespread implementer support is often not available, or the shape of a feature is not yet clear enough for implementers to feel comfortable pledging their support.

In such scenarios we anticipate features will be “incubated” outside of WHATWG standards. This could be in a variety of venues, such as:

* Another standards organization
* A personal document or GitHub repository
* A pull request to a WHATWG standard, with the understanding it will not be merged until the criteria above are met
* A document hosted by the WHATWG, but not under the spec.whatwg.org subdomain and not titled “Living Standard”

  EXAMPLE: The [CanvasColorSpace](https://wiki.whatwg.org/wiki/CanvasColorSpace) proposal is being incubated on the [WHATWG Wiki](https://wiki.whatwg.org/).

In all cases, features that hope to graduate to a WHATWG standard should strive to follow the above guidelines, gather appropriate implementer commitments, and have corresponding tests.

Additionally, those maintaining such proposals should try to involve the WHATWG community, for example by filing an issue on the standard they anticipate eventually becoming a part of.

NOTE: Overall, this process of incubation can be very lightweight, such as filing a pull request on the appropriate WHATWG standard with a proposal, and gathering appropriate implementer support there. Or it could be more involved, such as creating a separate repository at another venue and iterating for a long time there.

EXAMPLE: The addition of `URL.prototype.toJSON()` was rather straightforward once a plan was agreed upon and upstream IDL issues were resolved: [whatwg/url#137](https://github.com/whatwg/url/issues/137).

EXAMPLE: `innerText` was initially drafted in a [repository outside](https://github.com/rocallahan/innerText-spec) the HTML Standard. Integration into HTML then went rather smoothly: [whatwg/html#1678](https://github.com/whatwg/html/pull/1678).

## Tests

As discussed in [Changes](#changes), normative changes to a WHATWG standard requires tests, usually submitted to [web-platform-tests](https://github.com/w3c/web-platform-tests). At a high level, these tests should strive to:

* Be automated
* Test error handling
* Test limits and edge cases, such as overflow outside the expected value set

## Conflicts

In case of a conflict among the community of contributors, the editor is expected to go to significant length to resolve disagreements. In the end, they make a judgment call to pick the best option they believe will have multi-implementer support.

If a workstream participant believes the editor's choice will not have multi-implementer support, and they cannot convince the editor, then they may formally appeal to the Steering Group. In their capacity as implementers, the Steering Group may correct or uphold the editor's decision.

Implementations can always override the editor by implementing something else. Whenever that happens a breakdown in communication has taken place that the community should seek to overcome and find ways to prevent it from happening again.

Implementations that disagree can be rather tricky to sort out. Generally, we try to approach these situations as follows:

* Find a solution that is mutually acceptable.
* Research expectations of existing web content and specify the most web-compatible approach.
* Align with the majority.

NOTE: A standard is a tool towards convergence, and changing a standard can often be a pragmatic solution in case of conflict.

Implementation disagreement should not result in implementation-defined behavior or optional features.

## Anchor permanence

Often other standards want to reference parts of a WHATWG Living Standard by using a hypertext anchor. Since Living Standards are continually evolving, the set of anchors in a document is not static, and some anchors could disappear over time.

In general, editors should try to preserve anchors when reasonable. This includes using techniques like:

* For name changes, retaining the old anchor anyway, even if it doesn't match the new name. (This might be in addition to adding a new anchor aligned with the new name.)
* For removals, adding a note explaining what was formerly there, and why it is gone, having the old anchor now point to that note.

EXAMPLE: The `console` object changed from being a Web IDL interface to a Web IDL namespace. Although the Console Standard's new anchor is [#console-namespace](https://console.spec.whatwg.org/#console-namespace), the old anchor of [#console-interface](https://console.spec.whatwg.org/#console-interface) still works.

EXAMPLE: Although the concept of "structured cloning" has been replaced by structured serialization, the HTML Standard's [#structured-clone](https://html.spec.whatwg.org/multipage/structured-data.html#structured-clone) anchor points to a note explaining this evolution, so that old links do not break.

Consumers who need to reference exactly what a Living Standard said at a given point in time, for example to document what they implemented from or to explain the history of the web platform, can use the commit snapshots functionality. Each Living Standard has a "Snapshot as of this commit" link that gives a frozen copy for such historical reference. The WHATWG will keep these snapshots available at their published URLs permanently. However, other standards organizations are discouraged from referencing these snapshots, as they generally contain contain known issues that have been fixed in the Living Standard, and can mislead implementers and web developers.

For cases where another standards organization wishes to ensure an anchor is permanently available in the canonical Living Standard, they may file a new issue requesting a permanent anchor and detailing the anchor(s) they would like preserved. The editor can then discuss this request with the requestor; for example, if the editor was planning on making changes in the near future, maybe they would advise the requestor to hold off on linking to that anchor until the changes go through.

After discussion concludes, such requested anchors get promoted to be permanent. This means that it becomes a matter of WHATWG Policy to never break them without the requestor's assent. (This is enforced via technical means in the specification tooling.) If an editor has a strong reason for breaking the anchor in the future, they should reach out on the original issue thread to the requestor to discuss how to proceed. This may result in breaking the anchor with the requestor's assent, e.g., because the requestor is prepared to update their referring standard. Otherwise the anchor will have to be maintained in the standard in some manner.

<hr>

<footer>

<small>Copyright © 2018 WHATWG (Apple, Google, Mozilla, Microsoft). This work is licensed under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).</small>

</footer>
