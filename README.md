# CompilerSwiftAI

Swift Package for Compiler Inc's AI Backend API

## Getting started

Login to the [Compiler Developper Dshboard](https://developer.compiler.inc/) and choose "Create a new app".  Give it a name and description and you will be given an API key. Save that API key, this is the only time it will be shown to you. 

On the next page you will see an app ID. You will use that in your code and set up functions for use with Compiler inside your own project next.

## Setting up your Swift Project

In any file you want to interface with this framework, you need to import it:

```import CompilerSwiftAI```

At some central location, in your code set up a service:

```compiler = Service(apiKey: "<from-initial-app-creation>", appId: "<from-developer-dashboard-for-your-app")```

Next you create an enum for "CompilerFunction".

## Completing set up on the Developer Dashboard

On the same page that you got your AppID you will see you available commands, which will start with only one thing, a "NoOp" which is returned when no appropriate functions were found.  Head over to the "Command Builder" and open the tab for "Swift Enum Import".

