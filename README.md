# OSLogs

This package is designed to utilize modern xCode 15 logs and OSLog,
meanwile provide simple user interfce and welcome your changes.
This package utilize iOS, iPadOS, MacOS, tvOS, VisionOS system logs feature. 

Benefits:
* you have a native support of logs in the xCode console.
* your logs are available on the system logs level
* system stores your logs, your app storage is not used for it.
* you can request your app logs and system logs for your process too.

Drawbacks:
* you can get logs only from the current App launch. 
Logs from the previous launches can be gathered on the device, but not in the App process.
 
## Logs have simple interface
 
 ```
 Logs.main.log("Describe the context")
 Logs.main.info("Describe the context", event: "Points Purchase")
 Logs.main.error("Describe the context", error: error)
 ```
 ## It designed to be extendable between packages.
 
 You can extend loggers for each your module as simple as creating a logger instance in extension
 
 ```swift
 
 extension Logs {
     static let module = AppLogger(category: "Repository") // Repository module logs 
 }
 
OR 
 extension Logs {
     static let network = AppLogger(category: "net") // Networking 
 }
 
 extension Logs {
     static let model = AppLogger(category: "model") // Models 
 }
 ```
 
 and use this logger inside your module, so logs from different packages will be clear separated
 ```
 Logs.module.log("Describe the context")
 Logs.network.log("Describe the context")
 Logs.model.error("Error message")
 ```
 
 ## You can install hook / destination for all the logs
 
 ```
 Logs.add { type, _, message, event, error in
    switch type {
    case .error:
        SentrySDK.logger.info(message)
        SentrySDK.capture(error: message) // Creates an Error in the console 
    case .info:
        SentrySDK.logger.info(message)
        SentrySDK.addBreadcrumb(.init(level: .info, category: event)) // Adds a Bread crump 
        // or
        SentrySDK.capture(message: message) // Creates a Message in the console 
    case .default:
        SentrySDK.logger.info(message)
    default: break
    }
 }
 ```
 
 ## To retrieve logs
 
 Logs provide the application logs for the previous hour.
 as Data from String(utf-8)
 and you can write it in the file or send as attachment in the mail or Sentry
 ```
  let data = Logs.getLogData()
 ```
 
 We retrieve all logs and filter the Application ones. 
 You can modify the method to have other system logs reported.
