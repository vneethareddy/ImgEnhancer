//
//  MAImagePickerFinalViewController.m
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/10/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import "MAImagePickerFinalViewController.h"

#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#import "MAOpenCV.h"
#import "ImgEnhancer.h"

#define kMaxPortraitSize CGSizeMake (624.0f, 880.0f)
#define kMaxLandscapeSize CGSizeMake (880.0f, 624.0f)

@interface MAImagePickerFinalViewController ()

- (UILabel *) createLabelWithText : (NSString *)textStr;

@end

@implementation MAImagePickerFinalViewController

@synthesize firstSettingIcon = _firstSettingIcon;
@synthesize secondSettingIcon = _secondSettingIcon;
@synthesize thirdSettingIcon = _thirdSettingIcon;
@synthesize fourthSettingIcon = _fourthSettingIcon;

@synthesize activityIndicator = _activityIndicator;
@synthesize progressIndicator = _progressIndicator;

@synthesize finalImageView = _finalImageView;
@synthesize adjustedImage = _adjustedImage;
@synthesize sourceImage = _sourceImage;

@synthesize imageFrameEdited = _imageFrameEdited;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	UIImageView *imgV = nil;
	UIActivityIndicatorView *activityV = nil;
	
    [super viewDidLoad];
    
    [self setupToolbar];
    [self setupEditor];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.adjustedImage = self.sourceImage;
    
	imgV = [[UIImageView alloc] init];
    [imgV setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - (kCameraToolBarHeight + 70))];
    [imgV setContentMode:UIViewContentModeScaleAspectFit];
    [imgV setUserInteractionEnabled:YES];
    [imgV setImage: self.sourceImage];
    self.finalImageView = imgV;
	
    UIScrollView * imgScrollView = [[UIScrollView alloc] initWithFrame:self.finalImageView.frame];
    [imgScrollView setScrollEnabled:YES];
    [imgScrollView setUserInteractionEnabled:YES];
    [imgScrollView addSubview:self.finalImageView];
    [imgScrollView setMinimumZoomScale:1.0f];
    [imgScrollView setMaximumZoomScale:3.0f];
    [imgScrollView setDelegate:self];
    [self.view addSubview:imgScrollView];
    
	activityV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityV setFrame:CGRectMake(imgScrollView.frame.size.width / 2 - kActivityIndicatorSize / 2, imgScrollView.frame.size.height / 2 - kActivityIndicatorSize / 2, kActivityIndicatorSize, kActivityIndicatorSize)];
    [activityV setHidesWhenStopped:YES];
    [activityV stopAnimating];
	self.progressIndicator = activityV;
	
    [self.view addSubview: self.progressIndicator];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.finalImageView;
}


- (void)viewDidAppear:(BOOL)animated
{
	BOOL shouldRemember = NO;
    [super viewDidAppear:animated];
    
    int selectThis = 1;
    
	shouldRemember = [self shouldRememberLastFilterChoice];
	if (shouldRemember)
	{
		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"maimagepickercontrollerlasteditchoice"])
		{
			selectThis = [[NSUserDefaults standardUserDefaults] integerForKey:@"maimagepickercontrollerlasteditchoice"];
		}
		else
		{
			[[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"maimagepickercontrollerlasteditchoice"];
			selectThis = 2;
		}
	}
    
    switch (selectThis)
	{
        case 1:
            [self.firstSettingIcon sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
        case 2:
            [self.secondSettingIcon sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
        case 3:
            [self.thirdSettingIcon sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
        case 4:
            [self.fourthSettingIcon sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
    }
}

- (void)popCurrentViewController
{
	[self.presentingViewController dismissViewControllerAnimated: YES completion:
	 ^{
		 [self.plugin didCancelImgEnhancer];
	 }];
}

- (void)comfirmFinishedImage
{
	NSString *filePath = nil;
	[self rotateImageIfLandscape];
	filePath = [self storeImageToCache];
	[self.presentingViewController dismissViewControllerAnimated: YES completion:
	 ^{
		if (filePath)
		{
			[self.plugin didCompleteImgEnhancerWithPath: filePath];
		}
	 }];
}

- (BOOL) rotateImageIfLandscape
{
	BOOL didRotate = NO;
	
	if (self.adjustedImage.size.width > self.adjustedImage.size.height)
	{
		self.adjustedImage = [[UIImage alloc] initWithCGImage: self.adjustedImage.CGImage
                                                        scale: 1.0
                                                  orientation: UIImageOrientationRight];

		self.adjustedImage = [MAOpenCV imageByRotatingImage: self.adjustedImage fromImageOrientation: self.adjustedImage.imageOrientation];
		
		didRotate = YES;
	}
	
	return didRotate;
}

- (void)adjustPreviewImage
{
    CGSize destSize = CGSizeZero;
	CvSize size;
	BOOL shouldResize = NO;
	
	destSize = [self sizeToFitForImage: self.sourceImage];
	shouldResize = !CGSizeEqualToSize (destSize, self.sourceImage.size);
	if (shouldResize)
	{
		size = cvSize (destSize.width, destSize.height);
	}
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *adjustedImg = nil;
		
        self.adjustedImage = self.sourceImage;
        
        if (currentlySelected == 1)
        {
            cv::Mat original;
            original = [MAOpenCV cvMatFromUIImage:self.sourceImage];
			if (shouldResize)
			{
            	cv::resize(original, original, size);
			}
            adjustedImg = [MAOpenCV UIImageFromCVMat:original];
            self.adjustedImage = adjustedImg;
            
            original.release();
        }
        
        if (currentlySelected != 1)
        {
            
            cv::Mat original;
            
            if (currentlySelected == 2)
            {
				original = [MAOpenCV cvMatGrayFromUIImage:self.sourceImage];
                
                cv::GaussianBlur(original, original, cvSize(11,11), 0);
                cv::adaptiveThreshold(original, original, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 5, 2);
				
				if (shouldResize)
				{
					cv::resize(original, original, size);
				}
				
                adjustedImg = [MAOpenCV UIImageFromCVMat:original];
				self.adjustedImage = adjustedImg;
                
                original.release();
            }
            
            if (currentlySelected == 3)
            {
				original = [MAOpenCV cvMatGrayFromUIImage:self.sourceImage];
                
                cv::Mat new_image = cv::Mat::zeros( original.size(), original.type() );
                
                original.convertTo(new_image, -1, 1.4, -50);
                original.release();
                
				if (shouldResize)
				{
					cv::resize(new_image, new_image, size);
				}
                adjustedImg = [MAOpenCV UIImageFromCVMat: new_image];
				self.adjustedImage = adjustedImg;

                new_image.release();
            }
            
            if (currentlySelected == 4)
            {
                original = [MAOpenCV cvMatFromUIImage:self.sourceImage];
                
                cv::Mat new_image = cv::Mat::zeros( original.size(), original.type() );
                
                original.convertTo(new_image, -1, 1.9, -80);
                
                original.release();
                
				if (shouldResize)
				{
					cv::resize(new_image, new_image, size);
				}
                adjustedImg = [MAOpenCV UIImageFromCVMat:new_image];
				self.adjustedImage = adjustedImg;

                new_image.release();
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self updateImageView];
                       });
    });
}

- (CGSize) sizeToFitForImage: (UIImage *) image
{
	CGSize imgSize = CGSizeZero;
	CGSize maxSize = CGSizeZero;
	CGSize retSize = CGSizeZero;
	CGFloat ratioX = 0.0f;
	CGFloat ratioY = 0.0f;
	CGFloat ratio = 0.0f;
	
	imgSize = image.size;
	maxSize = kMaxPortraitSize;
	if (imgSize.width > imgSize.height)
	{
		maxSize = kMaxLandscapeSize;
	}
	retSize = imgSize;
	if (imgSize.width > maxSize.width || imgSize.height > maxSize.height)
	{
		ratioX = maxSize.width / imgSize.width;
		ratioY = maxSize.height / imgSize.height;
		ratio = ratioX;
		if (ratioX > ratioY)
		{
			ratio = ratioY;
		}
		retSize.width = imgSize.width * ratio;
		retSize.height = imgSize.height * ratio;
	}
	
	return retSize;
}

- (void) updateImageView
{
    [self.finalImageView setNeedsDisplay];
    [self.finalImageView setImage:self.adjustedImage];
    
    [self.progressIndicator stopAnimating];
    [self.view setUserInteractionEnabled:YES];
}

- (void) updateImageViewAnimated
{
    UIView *view = [_rotateButton valueForKey:@"view"];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI ];
    rotationAnimation.duration = 0.4;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1;
    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    [UIView transitionWithView:self.finalImageView
                      duration:0.4f
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{
                        self.finalImageView.image = self.adjustedImage;
                    } completion:NULL];
    
    [self.progressIndicator stopAnimating];
    [self.view setUserInteractionEnabled:YES];
}


- (NSString *)storeImageToCache
{
    NSString *tmpPath = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"maimagepickercontollerfinalimage.jpg"];
    NSData* imageData = UIImageJPEGRepresentation(self.adjustedImage, 1.0f);
    [imageData writeToFile:tmpPath atomically:NO];
	
	return tmpPath;
}

- (IBAction) filterChanged:(id) sender withEvent:(UIEvent *) event
{
    BOOL shouldRemember = NO;
    UIControl *control = sender;
    
    if (control.tag != currentlySelected)
    {
        [self.view setUserInteractionEnabled:NO];
        [self.progressIndicator setHidden:NO];
        [self.progressIndicator startAnimating];
        
        currentlySelected = control.tag;
		shouldRemember = [self shouldRememberLastFilterChoice];
		if (shouldRemember)
		{
	        [[NSUserDefaults standardUserDefaults] setInteger:currentlySelected forKey:@"maimagepickercontrollerlasteditchoice"];
		}
        
        [self.firstSettingIcon setSelected:NO];
        [self.secondSettingIcon setSelected:NO];
        [self.thirdSettingIcon setSelected:NO];
        [self.fourthSettingIcon setSelected:NO];
        
        [self.firstSettingIcon setEnabled:YES];
        [self.secondSettingIcon setEnabled:YES];
        [self.thirdSettingIcon setEnabled:YES];
        [self.fourthSettingIcon setEnabled:YES];
        
        int activityIndicatorOffset;
        
        
        switch (control.tag) {
            case 1:
                [self.firstSettingIcon setSelected:YES];
                [self.firstSettingIcon setEnabled:NO];
                activityIndicatorOffset = 22;
                break;
            case 2:
                [self.secondSettingIcon setSelected:YES];
                [self.secondSettingIcon setEnabled:NO];
                activityIndicatorOffset = 102;
                break;
            case 3:
                [self.thirdSettingIcon setSelected:YES];
                [self.thirdSettingIcon setEnabled:NO];
                activityIndicatorOffset = 182;
                break;
            case 4:
                [self.fourthSettingIcon setSelected:YES];
                [self.fourthSettingIcon setEnabled:NO];
                activityIndicatorOffset = 262;
                break;
        }
        
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^(void) {
                             [self.activityIndicator setFrame:CGRectMake(activityIndicatorOffset, 52, 43, 8)];
                         }
                         completion:NULL];
        
        [self adjustPreviewImage];
    }
    
}

- (void)setupEditor
{
	UIImageView *imgV = nil;
	UILabel *filterTextLbl = nil;
	
    UIView *editorView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - (kCameraToolBarHeight + 60), self.view.bounds.size.width, 60)];
    
    UIImageView *editorViewBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 31, self.view.bounds.size.width, 29)];
    [editorViewBackground setImage:[UIImage imageNamed:@"f-setting-tray"]];
    
    
    UIView *firstSetting = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, editorView.frame.size.height)];
    self.firstSettingIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    self.firstSettingIcon.accessibilityLabel = @"No Filter";
    [self.firstSettingIcon setFrame:CGRectMake(12, 0, 57, 46)];
    [self.firstSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-1"] forState:UIControlStateNormal];
    [self.firstSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-1-active"] forState:UIControlStateHighlighted];
    [self.firstSettingIcon setTag:1];
    [self.firstSettingIcon addTarget:self action:@selector(filterChanged:withEvent:) forControlEvents:UIControlEventTouchUpInside];
	
	filterTextLbl = [self createLabelWithText: @"Original"];
	
	[firstSetting addSubview: filterTextLbl];
    [firstSetting addSubview:self.firstSettingIcon];
	
    UIView *secondSetting = [[UIView alloc] initWithFrame:CGRectMake(80, 0, 80, editorView.frame.size.height)];
    self.secondSettingIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secondSettingIcon.accessibilityLabel = @"Text Only Enhance Filter";
    [self.secondSettingIcon setFrame:CGRectMake(12, 0, 57, 46)];
    [self.secondSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-2"] forState:UIControlStateNormal];
    [self.secondSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-2-active"] forState:UIControlStateHighlighted];
    [self.secondSettingIcon setTag:2];
    [self.secondSettingIcon addTarget:self action:@selector(filterChanged:withEvent:) forControlEvents:UIControlEventTouchUpInside];
	
	filterTextLbl = [self createLabelWithText: @"Text"];
	
	[secondSetting addSubview: filterTextLbl];
    [secondSetting addSubview:self.secondSettingIcon];
	
    UIView *thirdSetting = [[UIView alloc] initWithFrame:CGRectMake(160, 0, 80, editorView.frame.size.height)];
    self.thirdSettingIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    self.thirdSettingIcon.accessibilityLabel = @"Photo and Text Enhance Filter (Black and White)";
    [self.thirdSettingIcon setFrame:CGRectMake(12, 0, 57, 46)];
    [self.thirdSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-3"] forState:UIControlStateNormal];
    [self.thirdSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-3-active"] forState:UIControlStateHighlighted];
    [self.thirdSettingIcon setTag:3];
    [self.thirdSettingIcon addTarget:self action:@selector(filterChanged:withEvent:) forControlEvents:UIControlEventTouchUpInside];
	
	filterTextLbl = [self createLabelWithText: @"Gray"];
	
	[thirdSetting addSubview: filterTextLbl];
    [thirdSetting addSubview:self.thirdSettingIcon];
	
    UIView *fourthSetting = [[UIView alloc] initWithFrame:CGRectMake(240, 0, 80, editorView.frame.size.height)];
    self.fourthSettingIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fourthSettingIcon.accessibilityLabel = @"Photo Only Enhance Filter";
    [self.fourthSettingIcon setFrame:CGRectMake(12, 0, 57, 46)];
    [self.fourthSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-4"] forState:UIControlStateNormal];
    [self.fourthSettingIcon setBackgroundImage:[UIImage imageNamed:@"f-setting-4-active"] forState:UIControlStateHighlighted];
    [self.fourthSettingIcon setTag:4];
    [self.fourthSettingIcon addTarget:self action:@selector(filterChanged:withEvent:) forControlEvents:UIControlEventTouchUpInside];
	
	filterTextLbl = [self createLabelWithText: @"Color"];
	
	[fourthSetting addSubview: filterTextLbl];
    [fourthSetting addSubview:self.fourthSettingIcon];
	
	imgV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"f-setting-indicator-active"]];
    self.activityIndicator = imgV;
    
    [editorView addSubview:editorViewBackground];
    
    [editorView addSubview:firstSetting];
    [editorView addSubview:secondSetting];
    [editorView addSubview:thirdSetting];
    [editorView addSubview:fourthSetting];
    [editorView addSubview:self.activityIndicator];
    
    [self.view addSubview:editorView];
}

- (void)setupToolbar
{
	NSArray *arr = nil;
	
    UIToolbar *finishToolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - kCameraToolBarHeight, self.view.bounds.size.width, kCameraToolBarHeight)];
    [finishToolBar setBackgroundImage:[UIImage imageNamed:@"camera-bottom-bar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
	arr = [self createToolBarArray];
    
	[finishToolBar setItems: arr];
    
    [self.view addSubview:finishToolBar];
}

- (void)rotateImage
{
    switch (self.adjustedImage.imageOrientation)
    {
        case UIImageOrientationRight:
            self.adjustedImage = [[UIImage alloc] initWithCGImage: self.adjustedImage.CGImage
                                                        scale: 1.0
                                                  orientation: UIImageOrientationDown];
            break;
        case UIImageOrientationDown:
            self.adjustedImage = [[UIImage alloc] initWithCGImage: self.adjustedImage.CGImage
                                                        scale: 1.0
                                                  orientation: UIImageOrientationLeft];
            break;
        case UIImageOrientationLeft:
            self.adjustedImage = [[UIImage alloc] initWithCGImage: self.adjustedImage.CGImage
                                                        scale: 1.0
                                                  orientation: UIImageOrientationUp];
            break;
        case UIImageOrientationUp:
            self.adjustedImage = [[UIImage alloc] initWithCGImage: self.adjustedImage.CGImage
                                                        scale: 1.0
                                                  orientation: UIImageOrientationRight];
            break;
        default:
            break;
    }

    self.adjustedImage = [MAOpenCV imageByRotatingImage: self.adjustedImage fromImageOrientation: self.adjustedImage.imageOrientation];
    
    [self updateImageViewAnimated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear: animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSArray *) createToolBarArray
{
	NSMutableArray *arr = nil;
	
    UIBarButtonItem *undoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close-button"] style:UIBarButtonItemStylePlain target:self action:@selector(popCurrentViewController)];
    undoButton.accessibilityLabel = @"Return to Frame Adjustment View";
    
    _rotateButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"f-setting-rotate"] style:UIBarButtonItemStylePlain target:self action:@selector(rotateImage)];
    _rotateButton.accessibilityLabel = @"Rotate Image by 90 Degrees";
    
    UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"confirm-button"] style:UIBarButtonItemStylePlain target:self action:@selector(comfirmFinishedImage)];
    confirmButton.accessibilityLabel = @"Confirm adjusted Image";
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [fixedSpace setWidth:10.0f];
	
	arr = [[NSMutableArray alloc] initWithObjects:fixedSpace,undoButton,flexibleSpace,_rotateButton,flexibleSpace,confirmButton,fixedSpace, nil];
	
	return arr;
}

- (BOOL) shouldRememberLastFilterChoice
{
	return YES;
}

#pragma mark - Private Method
- (UILabel *) createLabelWithText : (NSString *)textStr
{
	UILabel *filterTextLbl = nil;
	
	filterTextLbl = [[UILabel alloc] initWithFrame: CGRectMake(12, 47, 57, 10)];
	filterTextLbl.text = textStr;
	filterTextLbl.textAlignment = NSTextAlignmentCenter;
	filterTextLbl.textColor = [UIColor whiteColor];
	filterTextLbl.backgroundColor = [UIColor clearColor];
	filterTextLbl.font = [UIFont systemFontOfSize: 8];
	
	return filterTextLbl;
}

@end
