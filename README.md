# Dingle Swift
[Dingle](https://github.com/Vmlweb/Dingle) Generator for Swift

## Installation

```bash
$ npm install --save dingle-swift
```

## Dependancies

You will need the following module in your project:

  * [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
  * [AFNetworking](https://github.com/AFNetworking/AFNetworking)
  * [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)
  
```javascript
pod 'SwiftyJSON', '~> 2.2.0'
pod 'AFNetworking', '~> 2.0'
pod 'CocoaAsyncSocket', '~> 7.4.0'
```

## Usage

Simply require the dingle generator module and specify the directory to build into:

```javascript
var dingle = require('dingle')({
    http_listen: '0.0.0.0',
    https_listen: '0.0.0.0',
    tcp_listen: '0.0.0.0',
    udp_listen: '0.0.0.0'
});

var generator = require('dingle-swift');
generator.generate(dingle, './exports/swift');
```

Then simply drop the files generated into your XCode project and use like so:

```swift
var myapi = require('./MYAPI.js');

myapi.login("admin@myawesomeapi.com", password: "mypassword") { (success, message, output) -> () in
	println(success)
	println(message)
	println(output)
}
```

## Hostnames

When the code is generated your hostnames are automatically taken from the dingle config but you can change it like so:

```swift
var myapi = MYAPI();

myapi.hostnames["http"] = "localhost:7691"
myapi.hostnames["https"] = "localhost:7692"
myapi.hostnames["tcp"] = "localhost:7693"
myapi.hostnames["udp"] = "localhost:7694"

myapi.login("admin@myawesomeapi.com", password: "mypassword") { (success, message, output) -> () in
	println(success)
	println(message)
	println(output)
}
```

## File Uploads

To upload a file simply specify a NSURL as a parameter as shown below:

```javascript
var myapi = MYAPI();

myapi.upload_file(NSURL(fileURLWithPath: "/Users/Me/Downloads/file.dump"), methods: [ "POST", "GET" ], callback: { (success, message, output) -> () in
	println(success)
	println(message)
	println(output)
}, uploading: { (size, remaining, percentage) -> Void in
	println("Upload at \(percentage)")
}, downloading: { (size, remaining, percentage) -> Void in
	println("Download at \(percentage)")
}, stream: nil)
```
 
## File Downloads

When downloading a file you must specify a NSOutputStream to write to and once the download is complete the stream will be returned in the output variable callback:

```javascript
var myapi = MYAPI();

myapi.download_file("admin@myawesomeapi.com", methods: [ "POST", "GET" ], callback: { (success, message, output) -> () in
	println(success)
	println(message)
	println(output)
}, uploading: { (size, remaining, percentage) -> Void in
	println("Upload at \(percentage)")
}, downloading: { (size, remaining, percentage) -> Void in
	println("Download at \(percentage)")
}, stream: NSOutputStream(toFileAtPath: "/Users/Me/Downloads/file.dump", append: false))
```

## Choosing Method

By default dingle will auto choose each method depending on the order of which they are specified in the function but we can override this like so:

```swift
var myapi = MYAPI();

myapi.login("admin@myawesomeapi.com", password: "mypassword", methods: [ "POST", "TCP" ]) { (success, message, output) -> () in
	println(success)
	println(message)
	println(output)
}
```

## Methods

The following methods are supported:

  * TCP
  * UDP
  * POST
  * GET
  * PUT
  * DELETE
  * OPTIONS
  * HEAD
  * PATCH
  * TRACE
  * CONNECT