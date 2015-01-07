//
//  MACaptureSession.m
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/5/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import "MACaptureSession.h"
#import <ImageIO/ImageIO.h>
#import "MAOpenCV.h"

@implementation MACaptureSession

@synthesize captureSession = _captureSession;
@synthesize previewLayer = _previewLayer;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize stillImage = _stillImage;

- (id)init
{
	if ((self = [super init]))
    {
		[self setCaptureSession:[[AVCaptureSession alloc] init]];

		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_didChangeOrientation:) name: UIDeviceOrientationDidChangeNotification object: nil];
	}
	return self;
}

- (void)addVideoPreviewLayer
{
	[self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];
	[_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
}

- (void)addVideoInputFromCamera
{
    AVCaptureDevice *backCamera;
    
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            if ([device position] == AVCaptureDevicePositionBack)
            {
                backCamera = device;
                [self toggleFlash];
            }
        }
    }
    
    NSError *error = nil;
    
    AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    
    if (!error)
    {
        if ([_captureSession canAddInput:backFacingCameraDeviceInput])
        {
            [_captureSession addInput:backFacingCameraDeviceInput];
        }
    }
}

- (void)setFlashOn:(BOOL)boolWantsFlash
{
    flashOn = boolWantsFlash;
    [self toggleFlash];
}

- (void)toggleFlash
{
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices)
    {
        if (device.flashAvailable) {
            if (flashOn)
            {
                [device lockForConfiguration:nil];
                device.flashMode = AVCaptureFlashModeOn;
                [device unlockForConfiguration];
            }
            else
            {
                [device lockForConfiguration:nil];
                device.flashMode = AVCaptureFlashModeOff;
                [device unlockForConfiguration];
            }
        }
    }
}

- (void)addStillImageOutput
{
    [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [[self stillImageOutput] setOutputSettings:outputSettings];
	   
//    AVCaptureConnection *videoConnection = nil;
//    
//    for (AVCaptureConnection *connection in [_stillImageOutput connections])
//    {
//        for (AVCaptureInputPort *port in [connection inputPorts])
//        {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
//            {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection)
//        {
//            break;
//        }
//    }
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    [_captureSession addOutput:[self stillImageOutput]];
	[self _setStillCaptureOrientation];	
}

- (void)captureStillImage
{
	AVCaptureConnection *videoConnection = nil;
	
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections])
    {
		for (AVCaptureInputPort *port in [connection inputPorts])
        {
			if ([[port mediaType] isEqual:AVMediaTypeVideo])
            {
				videoConnection = connection;
				break;
			}
		}
        
		if (videoConnection)
        {
            break;
        }
	}
	
	[_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:
     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
		 UIImageOrientation imgOrientation = UIImageOrientationRight;
		 
         if (imageSampleBuffer)
         {
             CFDictionaryRef exifAttachments = (CFDictionaryRef) CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
             if (exifAttachments)
             {
                 //SafeLog(@"attachements: %@", exifAttachments);
             } else
             {
                 //SafeLog(@"no attachments");
             }
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             UIImage *image = [[UIImage alloc] initWithData:imageData];
			 
			 // portrait, landscapeRight, upsidedown as is
			 // landscapeLeft, rotate 180
			 switch (image.imageOrientation)
			 {
				 case UIImageOrientationUp:
				 {
					 imgOrientation = UIImageOrientationRight;
					 
					 break;
				 }

				 case UIImageOrientationDown:
				 {
					 imgOrientation = UIImageOrientationLeft;
					 
					 break;
				 }

				 default:
				 {
					 imgOrientation = image.imageOrientation;
					 break;
				 }
			 }
			 UIImage *temp = [MAOpenCV imageByRotatingImage: image fromImageOrientation: imgOrientation];

             [self setStillImage: temp];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:kImageCapturedSuccessfully object:nil];
         }
     }];
}

- (void)dealloc {
    
	[[self captureSession] stopRunning];
	
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: UIDeviceOrientationDidChangeNotification object: nil];
    
	_previewLayer = nil;
	_captureSession = nil;
    _stillImageOutput = nil;
    _stillImage = nil;
}

#pragma mark - Private
- (void) _setStillCaptureOrientation
{
	AVCaptureConnection *videoConnection = nil;
	UIDeviceOrientation deviceOrientation = UIDeviceOrientationUnknown;
	
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections])
    {
		for (AVCaptureInputPort *port in [connection inputPorts])
        {
			if ([[port mediaType] isEqual:AVMediaTypeVideo])
            {
				videoConnection = connection;
				break;
			}
		}
        
		if (videoConnection)
        {
            break;
        }
	}
	if (videoConnection && self.stillImageOutput.isCapturingStillImage == NO)
	{
		deviceOrientation = [UIDevice currentDevice].orientation;
		switch (deviceOrientation)
		{
			case UIDeviceOrientationPortrait:
			case UIDeviceOrientationPortraitUpsideDown:
			case UIDeviceOrientationLandscapeLeft:
			case UIDeviceOrientationLandscapeRight:
			{
				videoConnection.videoOrientation = (AVCaptureVideoOrientation) deviceOrientation;
				
				break;
			}
				
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			case UIDeviceOrientationUnknown:
			default:
			{
				// Do Nothing
				break;
			}
		}
	}
}

- (void) _didChangeOrientation: (NSNotification *) notification
{
	[self _setStillCaptureOrientation];
}

@end
