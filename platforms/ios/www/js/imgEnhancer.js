// Image Enhancer Plugin
// This will launch a navigation controller as a model with the Enchancer View Controller

var ImgEnhancer = {
	enhanceImageWithData: function(data ,success, failure){
		cordova.exec(success, failure, "ImgEnhancer", "enhanceImageWithData", [data]);
	},

	enhanceImageWithPath: function(filePath, success, failure){
		cordova.exec(success, failure, "ImgEnhancer", "enhanceImageWithPath", [filePath]);
	}
};

module.exports = CustomCamera;