## GitHub Actions for Anypoint Exchange Sync

### TODO

 - [x] implement sync RAML action
 - [x] specify path
 - [ ] get token using clientid/clientsecret
 - [ ] publish status or deployment on GitHub after done
 - [x] snapshot support
 - [x] publish link in the logs to the exchange asset
 - [ ] specify tags: put link to the github code
 - [ ] release published to github
 - [ ] new snapshot if PR - to know it works before merged. Also add tag to the PR

## Ideas 

### Custom fields

Exchane support custom fields - UI elements that appear on the top of the asset page.
We can create following fields through API and assign them instead of tags:
 
 - githhub `commit-id`
 - github `username`
 - link to the github commit

 Those are Exchnage APIs that can be used
  - https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/exchange-experience-api/1.0.11/console/method/%231110/
  - https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/f1e97bc6-315a-4490-82a7-23abe036327a.anypoint-platform/exchange-experience-api/1.0.11/console/method/%231800/