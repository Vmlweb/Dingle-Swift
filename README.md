# Dingle Swift Alamofire
Swift Alamofire Generator for [Dingle](https://github.com/Vmlweb/Dingle)

## Installation

```bash
$ npm install --save dingle-swift-alamofire
```

## Methods

  * POST
  * GET
  * PUT
  * DELETE
  * OPTIONS
  * HEAD
  * PATCH
  * TRACE
  * CONNECT

## Usage

Simply require the dingle generator module and specify the directory to build into:

```javascript
var dingle = require('dingle')({
    http_listen: '0.0.0.0',
    https_listen: '0.0.0.0',
    tcp_listen: '0.0.0.0',
    udp_listen: '0.0.0.0'
});

var generator = require('dingle-swift-alamofire');
generator.generate(dingle, './exports');
```

## Dependancies

Once the exported classes have been put into XCode you will need the following frameworks:

  * [Alamofire](https://github.com/Alamofire/Alamofire)
  * [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)