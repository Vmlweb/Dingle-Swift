# Dingle Swift Alamofire
Dingle Swift Alamofire is a client code generator

## Installation

```bash
$ npm install --save dingle-swift-alamofire
```

## Usage

To start generate the swift files use the generate function of dingle:

```javascript
var dingle = require('dingle')({
	http_listen: '0.0.0.0',
	https_listen: '0.0.0.0',
	tcp_listen: '0.0.0.0',
	udp_listen: '0.0.0.0'
});

dingle.generate('dingle-swift-alamofire');
```