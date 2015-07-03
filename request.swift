//
//  <class>.swift
//  <class>
//
//  Created by Vmlweb on 27/05/2015.
//  Copyright (c) 2015 Vmlweb. All rights reserved.
//

import Foundation
import AFNetworking
import SwiftyJSON
import CocoaAsyncSocket

class <class> : NSObject, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate{
	
	//Hostnames
	var hostnames = Dictionary<String, String>()
	override init() {
		//hostnames["_METHOD_"] = "_URL_"
		<hostnames>
	}
	
	//Route Request
	func sendRequest(name: String, methods: Array<String>, params: [String : AnyObject],
		callback: (success: Bool, message: String, output: JSON?)->(),
		uploading: ((size: Double, remaining: Double, percentage: Double)->Void)?,
		downloading: ((size: Double, remaining: Double, percentage: Double)->Void)?, stream: NSOutputStream?){
	
		//Methods
		let http = [ "POST", "OPTIONS", "GET", "HEAD", "PUT", "PATCH", "DELETE", "TRACE", "CONNECT" ]
		for method in methods{
			
			//Route
			if method == "UDP" && hostnames["udp"] != nil{
				return dingleUDP(name, params: params, callback: callback)
				
			}else if method == "TCP" && hostnames["udp"] != nil{
				return dingleTCP(name, params: params, callback: callback)
				
			}else if contains(http, method) && (hostnames["https"] != nil || hostnames["http"] != nil){
				return dingleHTTP(name, method: method, params: params, callback: callback, uploading: uploading, downloading: downloading, stream: stream)
				
			}else{
				return callback(success: false, message: "Could not find method to call", output: nil)
			}
		}
			
	}
	
	//HTTP
	func dingleHTTP(name: String, method: String, params: [String : AnyObject],
		callback: (success: Bool, message: String, output: JSON?)->(),
		uploading: ((size: Double, remaining: Double, percentage: Double)->Void)?,
		downloading: ((size: Double, remaining: Double, percentage: Double)->Void)?, stream: NSOutputStream?){
	
		//Setup
		var serializer = AFHTTPRequestSerializer()
		var manager = AFURLSessionManager(sessionConfiguration: NSURLSessionConfiguration.defaultSessionConfiguration())
		var error: NSError? = nil
		
		//Check Params
		var files = [String : NSURL?]()
		var strings = [String : String]()
		for (key, value) in params{
				
			//Check if file
			if value is NSURL{
				files[key] = value as? NSURL
			}else{
				strings[key] = "\(value)"
			}
		}
			
		//Hostname
		var hostname : String
		if let connection = hostnames["https"]{
			hostname = "https://\(connection)/"
		}else if let connection = hostnames["http"]{
			hostname = "http://\(connection)/"
		}else{
			callback(success: false, message: "Could not find HTTP or HTTPS hostname", output: nil)
			return
		}
			
		//Make request
		var request = serializer.multipartFormRequestWithMethod(method, URLString: hostname + name + "/", parameters: strings, constructingBodyWithBlock: { (form) -> Void in
			//Add files
			for (key, value) in files{
				if let file = value{
					form.appendPartWithFileURL(file, name: key, error: &error)
				}
			}
		}, error: &error)
			
		//Error
		if let error = error{
			callback(success: false, message: error.localizedDescription, output: nil)
		}
			
		//Make Operation
		var operation = AFHTTPRequestOperation(request: request)
		operation.securityPolicy.allowInvalidCertificates = true
		if let stream = stream{
			operation.outputStream = stream
		}
			
		//Completed
		operation.setCompletionBlockWithSuccess({ (request, object) -> Void in
			if let type = request.response.allHeaderFields["Content-Disposition"] as? String{
					
				//Download
				if let stream = stream{
					callback(success: true, message: "Response written to stream", output: ["stream":stream])
				}else{
					callback(success: false, message: "Stream required to download this file", output: nil)
				}
			}else{
				
				//Stream
				if let stream = stream{
					callback(success: true, message: "Response written to stream", output: ["stream":stream])
				}else{
				
					//JSON?
					if let data = object as? NSData{
					
						//Read JSON
						let json = JSON(data: data)
						let success = json["success"].boolValue
						let message = json["message"].stringValue
						callback(success: success, message: message, output: json["output"])
					
					}else{
						callback(success: false, message: "Invalid JSON response", output: nil)
					}
				}
			}
		}, failure: { (request, error) -> Void in
			if error.code == -1009{
				callback(success: false, message: "Could not find server, please check your internet connection", output: nil)
			}else if error.code == -1004{
				callback(success: false, message: "Could not connect to server, please contact administrator", output: nil)
			}else{
				callback(success: false, message: error.localizedDescription, output: nil)
			}
		})
		
		//Downloading
		operation.setDownloadProgressBlock { (read, total, expected) -> Void in
			if let downloading = downloading{
				var expected = Double(expected)
				var total = Double(total)
				downloading(size: expected, remaining: total, percentage: total / expected)
			}
		}
			
		//Uploading
		operation.setUploadProgressBlock { (read, total, expected) -> Void in
			if let uploading = uploading{
				var expected = Double(expected)
				var total = Double(total)
				uploading(size: expected, remaining: total, percentage: total / expected)
			}
		}
		
		operation.start()
	}
	
	//TCP
	var tcpSocket : GCDAsyncSocket!
	var tcpCallback : ((success: Bool, message: String, output: JSON?)->())?
	func dingleTCP(name: String, params: [String : AnyObject], callback: (success: Bool, message: String, output: JSON?)->()){
		var error : NSError?
		
		//Connection
		var hostname : String
		var port : UInt16
		if let connection = hostnames["tcp"]{
			
			//Hostname
			if let hostname_check = find(connection, ":"){
				hostname = connection.substringToIndex(hostname_check)
			}else{
				callback(success: false, message: "Could not find a TCP hostname", output: nil)
				return
			}
			
			//Port
			if let port_check = find(connection, ":"){
				var port_string = connection.substringFromIndex(port_check)
				port_string.removeAtIndex(port_string.startIndex)
				port = UInt16(port_string.toInt()!)
			}else{
				callback(success: false, message: "Could not find a TCP port", output: nil)
				return
			}
		}else{
			callback(success: false, message: "Could not find TCP hostname", output: nil)
			return
		}
		
		//Setup socket
		tcpSocket = GCDAsyncSocket(delegate:self, delegateQueue: dispatch_get_main_queue())
		tcpSocket.connectToHost(hostname, onPort: port, error: &error)
		tcpCallback = callback
		
		//Error
		if let error = error {
			callback(success: false, message: error.localizedDescription, output: nil)
			return
		}
		
		//Send
		var name = "/\(name)/"
		var message = name.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
		tcpSocket.writeData(message, withTimeout: -1, tag: 0)
		tcpSocket.readDataWithTimeout(-1, tag: 0)
		NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("tcpTimeout"), userInfo: nil, repeats: false)
	}
	func tcpTimeout(){
		if let callback = tcpCallback{
			callback(success: false, message: "Could not find server, please check your internet connection", output: nil)
			tcpClose()
		}
	}
	func tcpClose(){
		tcpSocket.disconnect()
		tcpSocket = nil
		tcpCallback = nil
	}
	func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
		if let callback = tcpCallback{
			if err.code == 8{
				callback(success: false, message: "Could not find server, please check your internet connection", output: nil)
			}else if err.code == 61{
				callback(success: false, message: "Could not connect to server, please contact administrator", output: nil)
			}else{
				callback(success: false, message: err.localizedDescription, output: nil)
			}
			tcpClose()
		}
	}
	func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
		if let callback = tcpCallback{
			
			//JSON?
			if let data = data{
				
				//Read JSON?
				let json = JSON(data: data)
				let success = json["success"].boolValue
				let message = json["message"].stringValue
				callback(success: success, message: message, output: json["output"])
				tcpClose()
				
			}else{
				callback(success: false, message: "Invalid JSON response", output: nil)
				tcpClose()
			}
		}
	}
	
	//UDP
	var udpSocket : GCDAsyncUdpSocket!
	var udpCallback : ((success: Bool, message: String, output: JSON?)->())?
	func dingleUDP(name: String, params: [String : AnyObject], callback: (success: Bool, message: String, output: JSON?)->()){
		var error : NSError?
		
		//Connection
		var hostname : String
		var port : UInt16
		if let connection = hostnames["udp"]{
			
			//Hostname
			if let hostname_check = find(connection, ":"){
				hostname = connection.substringToIndex(hostname_check)
			}else{
				callback(success: false, message: "Could not find a UDP hostname", output: nil)
				return
			}
			
			//Port
			if let port_check = find(connection, ":"){
				var port_string = connection.substringFromIndex(port_check)
				port_string.removeAtIndex(port_string.startIndex)
				port = UInt16(port_string.toInt()!)
			}else{
				callback(success: false, message: "Could not find a UDP port", output: nil)
				return
			}
		}else{
			callback(success: false, message: "Could not find UDP hostname", output: nil)
			return
		}
		
		//Setup socket
		udpSocket = GCDAsyncUdpSocket(delegate:self, delegateQueue: dispatch_get_main_queue())
		udpSocket.bindToPort(0, error: &error)
		udpSocket.connectToHost(hostname, onPort: port, error: &error)
		udpSocket.beginReceiving(&error)
		udpCallback = callback
		
		//Error
		if let error = error {
			callback(success: false, message: error.localizedDescription, output: nil)
			return
		}
		
		//Send
		var message = "/\(name)/".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
		udpSocket.sendData(message, withTimeout: -1, tag: 0)
		NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("udpTimeout"), userInfo: nil, repeats: false)
	}
	func udpTimeout(){
		if let callback = udpCallback{
			callback(success: false, message: "Could not connect to server, please contact administrator", output: nil)
			udpClose()
		}
	}
	func udpClose(){
		udpSocket.close()
		udpSocket = nil
		udpCallback = nil
	}
	func udpSocket(sock: GCDAsyncUdpSocket!, didNotConnect error: NSError!) {
		if let callback = udpCallback{
			if error.code == 8{
				callback(success: false, message: "Could not find server, please check your internet connection", output: nil)
			}else{
				callback(success: false, message: error.localizedDescription, output: nil)
			}
			udpClose()
		}
	}
	func udpSocket(sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {
		if let callback = udpCallback{
			callback(success: false, message: error.localizedDescription, output: nil)
			udpClose()
		}
	}
	func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
		if let callback = udpCallback{
			
			//JSON?
			if let data = data{
				
				//Read JSON?
				let json = JSON(data: data)
				let success = json["success"].boolValue
				let message = json["message"].stringValue
				callback(success: success, message: message, output: json["output"])
				udpClose()
				
			}else{
				callback(success: false, message: "Invalid JSON response", output: nil)
				udpClose()
			}
		}
	}
	
	//Request Functions
	/*
	func _NAME_(_PARAMS_, callback: (success: Bool, message: String, output: JSON?)->()){
		_NAME_(_PARAMS_, callback: callback, uploading: nil, downloading: nil, stream: nil)
	}
	func _NAME_(_PARAMS_,
		callback: (success: Bool, message: String, output: JSON?)->(),
		uploading: ((size: Double, remaining: Double, percentage: Double)->Void)?,
		downloading: ((size: Double, remaining: Double, percentage: Double)->Void)?, stream: NSOutputStream?){
	
		//Parameters
		var params = [String : AnyObject]()
		if let value = _PARAM_{
			if value is NSURL{
				params["_PARAM_"] = value as? NSURL
			}else{
				params["_PARAM_"] = "\(value)"
			}
		}
			
		//Execute
		sendRequest("_NAME_", methods: [ "_METHODS_" ], params: params, callback: callback, uploading: uploading, downloading: downloading, stream: stream)
	}
	*/
<functions>
}