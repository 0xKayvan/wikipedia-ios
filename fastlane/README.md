fastlane documentation
================
# Installation
```
sudo gem install fastlane
```
# Available Actions
## iOS
### ios checkout
```
fastlane ios checkout
```
Checks out the sha specified in the environment variables or the develop branch
### ios analyze
```
fastlane ios analyze
```
Runs linting (and eventually static analysis)
### ios verify_test_platforms
```
fastlane ios verify_test_platforms
```
Runs tests on the primary platforms and configurations
### ios verify
```
fastlane ios verify
```
Runs unit tests, optionally generating a JUnit report.
### ios bump_patch
```
fastlane ios bump_patch
```
Increment the app version patch
### ios bump_minor
```
fastlane ios bump_minor
```
Increment the app version minor
### ios bump_major
```
fastlane ios bump_major
```
Increment the app version major
### ios tag_beta
```
fastlane ios tag_beta
```
Add a tag for the current build number and push to repo.
### ios tag_release
```
fastlane ios tag_release
```
Add a tag for the current version number push to repo.
### ios build
```
fastlane ios build
```
Build the app for distibution
### ios push_beta
```
fastlane ios push_beta
```
Runs tests, version, tag, and push to the beta branch
### ios test_and_push_beta
```
fastlane ios test_and_push_beta
```
Runs tests, version, tag, and push to the beta branch
### ios submit_release
```
fastlane ios submit_release
```
Runs tests, version, tag, and push to the beta branch

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane/tree/master/fastlane).
