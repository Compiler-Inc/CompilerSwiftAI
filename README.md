# CompilerSwiftAI

Swift Package for Compiler Inc's AI Backend API

## Getting started

Login to the [Compiler Developer Dashboard](https://developer.compiler.inc/) and choose "Create a new app".  Give it a name and description and you will be given an API key. Save that API key, this is the only time it will be shown to you. 

On the next page you will see an app ID. You will use that in your code and set up functions for use with Compiler inside your own project next.

## Setting up your Swift Project

In any file you want to interface with this framework, you need to import it:

```import CompilerSwiftAI```

At some central location, in your code set up a client:

```compiler = CompilerClient(appID: "<from-developer-dashboard-for-your-app>")```

Next you create an enum for "CompilerFunction".  This enum conforms `Sendable` and contains a case for each function you're making available.  for example:

```swift
enum CompilerFunction: Sendable {
    case doSomething
    case doSomethingElse
    case doSomethingWithParameters(someParameter: String, anotherParameter: Double)
}
```

Note that parameters supported are: `String`, `Double`, `Float`, `Int`, `Bool`, `Array` and `Dictionary`.

But, you'll want to add tradtional Swift-style documentation generating comments as well, because these will be use in a later step to help train the AI to best respond to your users. For instance:

```swift
enum CompilerFunction {
    /// Users can invoke this function to make something happen
    case doSomething

    /// This is a function that does something else
    case doSomethingElse

    /// This is another function, but this one now needs to contains exactly two parameters
    /// - Parameters:
    ///   - someParameter: This string describes the function type
    ///   - anotherParameter: This is a numeric value, and can only have values between 1 and 30 (for example)
    case doSomethingWithParameters(someParameter: String, anotherParameter: Double)
}
```

Be as descriptive as you can be. It will definitely help.  You can limit strings to certain values, give ranges for numeric values, and provide variations of ways a user might word this function, different nomenclature that might be used for the same function or parameters.

There are more things that you'll want to add to the CompilerFunction enum, but in the next step the dashboard will generate a template for the code you will add later.

## Completing set up on the Developer Dashboard

On the same page that you got your AppID you will see you available functions, which will start with only one thing, a "NoOp" which is returned when no appropriate functions were found.  Head over to the "Function Builder" and open the tab for "Swift Enum Import".  In the Swift text area, paste in the complete text of the `CompilerFunctionGenerator` enum:

