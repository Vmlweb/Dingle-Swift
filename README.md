# Dingle Swift
[Dingle](https://github.com/Vmlweb/Dingle) Generator for Swift

## Installation

```bash
$ npm install --save dingle-swift
```

## Dependancies

You will need the following frameworks in your XCode proect:

  * [Alamofire](https://github.com/Alamofire/Alamofire)
  * [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

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
generator.generate(dingle, './exports');
```

Once the files are generated into the specified directory simply drop them into your XCode project and execute like so:

```swift
MYAPP.users_forgot_username("admin@myawesomeapi.com", password: "myawesomepassword") { (success, message, output) -> () in
	print(success);
	print(message);
	print(output);
}
```
 
## Methods

The following methods are supported:

  * POST (Does not support file upload/downloads)
  * GET
  * PUT
  * DELETE
  * OPTIONS
  * HEAD
  * PATCH
  * TRACE
  * CONNECT