# opportunity_express_ipad_client

## Getting Started

These instructions will get you a copy of the iOS app up and running on your local machine in the iOS simulator for development.

### Prerequisities

```
OS X - El Capitan Operating System (v 10.11.xx)
Xcode Version 7.3.1 (v 7D1014)
```

which will come with

```
Apple Swift version 2.2 (swiftlang-703.0.18.8 clang-703.0.31)

^^ output of 'swift -version' command
```

Install carthage with homebrew.

```
brew install carthage
```

Good tutorial [here](https://www.raywenderlich.com/109330/carthage-tutorial-getting-started)

There will be a Cartfile with the projects dependencies included in this repo


```
carthage update --platform iOS

```

This command checks out the Cartfile dependencies and builds .framework files for the platform passed as --platform option.
The frameworks should be referenced in the project already and you just need to build them so that they are built and available when the project goes to find the files. Currently the src code for the libraries is checked into the repo.


You will need to make sure the base urls in LoginManager are pointed to http://localhost:8000/ if you want to use your local servers for testing. Also, you can test against the staging servers if you are in the office and on the ebprivate wifi network (https://acme1-customer.ngtcloud.com/).

Run the project on an iPad simulator. Make sure your opportunity servers are running.  When you first start it up it will hit the customer site and check on the status of the device. If you get a message saying the device is not provisioned... go to your database and flip the provisioned and enabled flags to true and click retry on the iPad.
