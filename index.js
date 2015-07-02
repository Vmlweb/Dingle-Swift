var fs = require('fs');
var path = require('path');
var mkdirp = require('mkdirp');
var val = require('validator');
var replace = require("replaceall");

//Generate
exports.generate = function(dingle,  directory){
	directory = path.join(process.cwd(), directory);
	
	//Hostname
	var hostnames = '';
	if (dingle.config.https.listen != '' && dingle.config.https.hostname != ''){
		hostnames += 'hostnames["https"] = "' + dingle.config.https.hostname + ':' + dingle.config.https.port + '"\n';
	}
	if (dingle.config.http.listen != '' && dingle.config.http.hostname != '' ){
		hostnames += 'hostnames["http"] = "' + dingle.config.http.hostname + ':' + dingle.config.http.port + '"\n';
	}
	if (dingle.config.tcp.listen != '' && dingle.config.tcp.hostname != '' ){
		hostnames += 'hostnames["tcp"] = "' + dingle.config.tcp.hostname + ':' + dingle.config.tcp.port + '"\n';
	}
	if (dingle.config.udp.listen != '' && dingle.config.udp.hostname != '' ){
		hostnames += 'hostnames["udp"] = "' + dingle.config.udp.hostname + ':' + dingle.config.udp.port + '"\n';
	}
	
	//Generate
	var functions = '';
	for (func in dingle.functions){
		functions += generate(dingle.functions[func]) + '';
	}
	
	//Make
	var filename = path.join(directory, dingle.config.app.prefix + '.swift');
	var contents = fs.readFileSync(path.join(__dirname + '/request.swift')).toString();
	contents = replace("<class>", dingle.config.app.prefix, contents);
	contents = replace("<hostnames>", hostnames, contents);
	contents = replace("<functions>", functions, contents);
	
	//Write file
	mkdirp(path.dirname(filename), function (error) {
		if (error){
			throw error;
		}else{
			fs.writeFile(filename, contents, function(error){
				if (error){
					throw error;
				}else{
					return;
				}
			});
		}
	});
}

//Each Call
function generate(func){
	
	//Parameters
	var param_method = [];
	var param_calling = [];
	for(var key in func.params) {
		var obj = func.params[key];
		
		//Compare
		var kind = 'String';
		try{
			if (obj.validator('true') === true){ kind = 'Bool'; }
		}catch(error){ }
		try{
			if (obj.validator('123') === 123){ kind = 'Int'; }
		}catch(error){ }
		try{
			if (obj.validator('123.123') === 123.123){ kind = 'Double'; }
		}catch(error){ }
		var file = { path: '/test/', size: 1 }
		try{
			if (obj.validator(file) === file){ kind = 'NSURL'; }
		}catch(error){ }
		
		//Calling
		if (param_calling.length == 0){
			param_calling.push(key);
		}else{
			param_calling.push(key + ': ' + key);
		}
		
		//Optional
		if (!obj.required){
			param_method.push(key + ': ' + kind  + '?');
		}else{
			param_method.push(key + ': ' + kind);
		}
	}
	
	//Parameters
	var method_values = [];
	for(var key in func.methods) { method_values.push(func.methods[key]); }
	
	//Generate
	var str = 'func ' + func.name + '(' + param_method.join(', ') + ', callback: (success: Bool, message: String, output: JSON?)->()){\n';
	str += '		' + func.name + '(' + param_calling.join(', ') + ', methods: [ "' + method_values.join('", "') + '" ], callback: callback, uploading: nil, downloading: nil, stream: nil)\n';
	str += '	}\n';
	str += '	func ' + func.name + '(' + param_method.join(', ') + ', methods: Array<String>, callback: (success: Bool, message: String, output: JSON?)->()){\n';
	str += '		' + func.name + '(' + param_calling.join(', ') + ', methods: methods, callback: callback, uploading: nil, downloading: nil, stream: nil)\n';
	str += '	}\n';
	str += '	func ' + func.name + '(' + param_method.join(', ') + ',\n';
	str += '		methods: Array<String>,\n';
	str += '		callback: (success: Bool, message: String, output: JSON?)->(),\n';
	str += '		uploading: ((size: Double, remaining: Double, percentage: Double)->Void)?,\n';
	str += '		downloading: ((size: Double, remaining: Double, percentage: Double)->Void)?, stream: NSOutputStream?){\n';
	str += '\n';
	str += '		//Parameters\n';
	str += '		var params = [String : AnyObject]()\n';
	for(var key in func.params) {
		var obj = func.params[key];
		if (!obj.required){
	str += '		if let value = ' + key + '{\n';
	str += '			params["' + key + '"] = value\n';
	str += '		}\n';
		}else{
	str += '		params["' + key + '"] = ' + key + '\n';
		}
	}
	str += '\n';
	str += '		//Execute\n';
	str += '		sendRequest("' + func.name + '", methods: methods, params: params, callback: callback, uploading: uploading, downloading: downloading, stream: stream)\n';
	str += '	}\n';
	
	return str;
}