## GitHub Actions for Anypoint Exchange Sync

## How it works

The action can be used in 3 types of flows/events:

 - `push` event
 - `pull_request` event: opened or `synchronized`
 - `release` event

Action behaves differently based on the used flow/event.
You can enable action for any number of supported flows.
It's up to you to define your workflow.

### Push

When the code is pushed `push` flow will be triggered.
This event should be only used on the master branch.
New asset will be published automatically with the version in the format:
`${latest-tag}-NEXT`.

### Pull Request

When Pull request is opened or synchronized we will publish new version of the asset
with the version in the format: `${latest-tag}-PR-${PR_NUMBER}`

## Recommended use

Recommened use is to enable this action on all supported flows/events.
`Push` and `pull_request` are good tools for CI, while `release` is for CD.

### Release

When release is created we will publish release version of the asset to Exchnage with the 
exact version that comes from git tag.

### TODO

 - [ ] get token using clientid/clientsecret
 - [ ] publish status or deployment on GitHub after done
 - [ ] record demo
 - [ ] extra checks for events

## Ideas 

### Custom fields

Exchane support custom fields - UI elements that appear on the top of the asset page.
We can create following fields through API and assign them instead of tags:
 
 - github `commit-id`
 - github `username`
 - link to the github commit

 Those are Exchnage APIs that can be used
  - https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/exchange-experience-api/1.0.11/console/method/%231110/
  - https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/exchange-experience-api/1.0.11/console/method/%231800/