var fs = require('fs');
var path = require('path');
var mkdirp = require('mkdirp');

module.exports.methods = [ "GET", "PUT", "DELETE", "POST" ];

//Setup
module.exports.setup = function(config, type, dir, call){
	var str = '';

	//Generate File
	str+= 'import Foundation\n'
	str+= 'import Alamofire\n'
	str+= 'import SwiftyJSON\n'
	
	str+= 'class ' + config.app.prefix + ' {\n'
	str+= '	class func sendRequest(url: String, method: Alamofire.Method, params: Dictionary<String,String>, callback:(success: Bool, message: String, output: Dictionary<String,AnyObject>)->()) {\n'
	str+= '		Alamofire.request(method, url, parameters:params).validate(statusCode: 200..<501).validate(contentType: ["application/json"]).responseJSON{(req, res, json, error) in\n'
	str+= '			if(error != nil) {\n'
	str+= '				if error?.code == -1 || error?.code == -1005{\n';
	str+= '					callback(success: false, message:"Could not reach server, please check your internet connection", output: [:])\n'
	str+= '				}else if error?.code == -1202{\n';
	str+= '					callback(success: false, message:"A valid SSL certificate could not be found on the server", output: [:])\n'
	str+= '				}else{\n'
	str+= '					callback(success: false, message: error!.localizedDescription, output: [:])\n'
	str+= '				}\n'
	str+= '			}else {\n'
	str+= '				var json = JSON(json!)\n'
	str+= '				callback(success: json["success"].boolValue, message: json["message"].stringValue, output: json["output"].dictionaryObject!)\n'
	str+= '			}\n'
	str+= '		}\n'
	str+= '	}\n'
	str+= '}'
	
	write(path.join(dir, config.app.prefix + '.swift'), str);
}
	
//Each Call
module.exports.generate = function(config, type, dir, call, hostname){
	var str = '';
	
	//Params
	var methodParam = ""
	var reqParam = ""
	for (var param in call.module.params){
		var obj = call.module.params[param];
		
		//Compare
		var kind = '';
		if (obj.validate.toString() == type.bool.toString()){
			kind = 'Bool';
		}else if (obj.validate.toString() == type.int.toString()){
			kind = 'Int';
		}else if (obj.validate.toString() == type.float.toString()){
			kind = 'Double';
		}else{
			kind = 'String';
		}
		
		//Optional
		var optional = '';
		if (!obj.required){
			optional = '?';
		}
		
		//Construct
		methodParam += param + ': ' + kind + optional + ','
		reqParam += '"' + param + '": "\\(' + param + ')",'
	}
	reqParam = reqParam.slice(0,-1);
	
	//No params
	if (reqParam == ''){
		reqParam = ':';
	}

	//Generate File	
	str+= 'import Foundation\n'
	str+= 'import Alamofire\n'
	str+= 'import SwiftyJSON\n'
	str+= 'extension ' + config.app.prefix + '{\n'
	str+= '	class func ' + call.name + '(' + methodParam + 'callback: (success: Bool, message: String, output: Dictionary<String, AnyObject>)->()){\n'
	str+= '		self.sendRequest("' + hostname + '", method: .' + call.module.method + ', params: [' + reqParam + '], callback: callback)\n'
	str+= '	}\n'
	str+= '}'
	
	//Make directory and file
	write(path.join(dir, config.app.prefix + '_' + call.name + '.swift'), str);
}

//Write File
function write(filename, contents){
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