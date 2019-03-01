## GitHub Actions for Anypoint Exchange Sync

## Problem

Often, you have your RAML files in the GitHub repo and you need to syncronize them
with Anypoint Exchange.

A lot of teams do it either manually or setup custom steps in the build pipelines.

Those days are gone.
With the release of GitHub Actions it's possible to build flexible workflows 
and import/reuse `raml synchonization` action in your workflows without 
inventing anything.

## How it works

The action can be used in 3 types of flows/events:

 - `push` event. We recommend to chain it with `Filter Master Branch` GitHub Action
 - `pull_request` event: opened or `synchronized`
 - `release` event

Action behaves differently based on the used flow/event.
You can enable action for any number of supported flows.
It's up to you to define your workflow.

### Push

When the code is pushed `push` flow will be triggered.
This event should be only used on the master branch.
New asset will be published automatically with the version in the format:
`${latest-tag}-NEXT`. *Note*, if repo has new tags then the version will be `0.0.1-NEXT`. 

### Pull Request

When Pull request is opened or synchronized we will publish new version of the asset
with the version in the format: `${latest-tag}-PR-${PR_NUMBER}`.
*Note*, if repo has new tags then the version will be `0.0.1-PR-${PR_NUMBER}`. 

## Recommended use

Recommened use is to enable this action on all supported flows/events.
`Push` and `pull_request` are good tools for CI, while `release` is for CD.

### Release

When release is created we will publish release version of the asset to Exchnage with the 
exact version that comes from git tag.

### TODO

 - [ ] publish status or deployment on GitHub after done
 - [ ] record demo

### Workflow

To include this action just add following code to your flow.

Handle `push` event and publish `snapshot`:

```
workflow "On Push" {
  resolves = ["sync-raml"]
  on = "push"
}

action "sync-raml" {
  uses = "repetitive/actions/exchange-sync@feature/exchange-sync"
  args = "-o a95e7484-821e-4c5a-ac7f-f357dec2c2c2 -a helloworld -p raml -m api.raml"
  secrets = [
    "ANYPOINT_PASSWORD",
  ]
  env = {
    ANYPOINT_USERNAME = "brian-nazareth"
  }
}
```

Handle `pull_request` event and publish `snapshot`:

```
workflow "On Pull Request" {
  resolves = ["sync-raml"]
  on = "pull_request"
}

action "sync-raml" {
  uses = "repetitive/actions/exchange-sync@feature/exchange-sync"
  args = "-o a95e7484-821e-4c5a-ac7f-f357dec2c2c2 -a helloworld -p raml -m api.raml"
  secrets = [
    "ANYPOINT_PASSWORD",
  ]
  env = {
    ANYPOINT_USERNAME = "brian-nazareth"
  }
}
```

Handle `release` event and publish `release`:

```
workflow "On Release" {
  resolves = ["sync-raml"]
  on = "release"
}

action "sync-raml" {
  uses = "repetitive/actions/exchange-sync@feature/exchange-sync"
  args = "-o a95e7484-821e-4c5a-ac7f-f357dec2c2c2 -a helloworld -p raml -m api.raml"
  secrets = [
    "ANYPOINT_PASSWORD",
  ]
  env = {
    ANYPOINT_USERNAME = "brian-nazareth"
  }
}
```

## Ideas 

### Other types

For now the only supported asset type is `RAML`.
Adding other types is doable.

### Custom fields

Exchane support custom fields - UI elements that appear on the top of the asset page.
We can create following fields through API and assign them instead of tags:
 
 - github `commit-id`
 - github `username`
 - link to the github commit

 Those are Exchnage APIs that can be used
  - https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/exchange-experience-api/1.0.11/console/method/%231110/
  - https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/exchange-experience-api/1.0.11/console/method/%231800/

 ### User defined tags

 We can allow user to pass tags into the Action as argument. 