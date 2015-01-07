//
//  ImgEnhancer.m
//  HelloCordova
//
//  Created by Libin Varghese on 29/12/14.
//
//

#import "ImgEnhancer.h"
#import "MAImagePickerFinalViewController.h"

@interface ImgEnhancer ()

@property (nonatomic, strong) CDVInvokedUrlCommand *latestCommand_;
@property (nonatomic, strong) UINavigationController *modalVC_;

@end

@implementation ImgEnhancer

- (void) enhanceImageWithData: (CDVInvokedUrlCommand *) command
{
	NSData *data = nil;
	UIImage *image = nil;
	
	@try
	{
		// Save the CDVInvokedUrlCommand as a property.  We will need it later.
		self.latestCommand_ = command;
		
		data = command.arguments[0];
		if (data.length == 0)
		{
			@throw [NSException exceptionWithName: NSInvalidArgumentException
										   reason: @"No Data"
										 userInfo: nil];
		}
		
		image = [[UIImage alloc] initWithData: data];
		if (image == nil)
		{
			@throw [NSException exceptionWithName: NSInvalidArgumentException
										   reason: @"Invalid Data"
										 userInfo: nil];
		}
		[self _enhanceImage: image];
	}
	@catch (NSException *exception)
	{
		CDVPluginResult *result = nil;
		
		result = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
								   messageAsString: [exception description]];
		
		[self.commandDelegate sendPluginResult: result callbackId: self.latestCommand_.callbackId];
	}
}

- (void) enhanceImageWithPath: (CDVInvokedUrlCommand *) command
{
	NSString *urlStr = nil;
	NSURL *url = nil;
	NSString *path = nil;
	UIImage *image = nil;
	
	@try
	{
		// Save the CDVInvokedUrlCommand as a property.  We will need it later.
		self.latestCommand_ = command;
		
		urlStr = command.arguments[0];
		url = [[NSURL alloc] initWithString: urlStr];
		path = [url path];
		if (path.length == 0)
		{
			@throw [NSException exceptionWithName: NSInvalidArgumentException
										   reason: @"No Path"
										 userInfo: nil];
		}
		
		image = [[UIImage alloc] initWithContentsOfFile: path];
		if (image == nil)
		{
			@throw [NSException exceptionWithName: NSInvalidArgumentException
										   reason: @"Invalid File"
										 userInfo: nil];
		}
		[self _enhanceImage: image];
	}
	@catch (NSException *exception)
	{
		CDVPluginResult *result = nil;
		
		result = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
								   messageAsString: [exception description]];
		
		[self.commandDelegate sendPluginResult: result callbackId: self.latestCommand_.callbackId];
	}
}

- (void) _enhanceImage: (UIImage *) image
{
	MAImagePickerFinalViewController *vc = nil;
	UINavigationController *navC = nil;
	
	// Create the modal stack
	vc = [[MAImagePickerFinalViewController alloc] initWithNibName: nil bundle: nil];
	vc.sourceImage = image;
	vc.plugin = self;
	navC = [[UINavigationController alloc] initWithRootViewController: vc];
	navC.navigationBarHidden = YES;
	self.modalVC_ = navC;
	
	// Display the view.  This will "slide up" a modal view from the bottom of the screen.
	[self.viewController presentViewController: self.modalVC_
									  animated: YES
									completion: nil];
}

- (void) didCancelImgEnhancer
{
	CDVPluginResult *result = nil;
	
	result = [CDVPluginResult resultWithStatus: CDVCommandStatus_NO_RESULT];
	
	[self.commandDelegate sendPluginResult: result callbackId: self.latestCommand_.callbackId];
}

- (void) didCompleteImgEnhancerWithPath: (NSString *) path
{
	CDVPluginResult *result = nil;
	
	result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: path];
	
	[self.commandDelegate sendPluginResult: result callbackId: self.latestCommand_.callbackId];
}

@end
