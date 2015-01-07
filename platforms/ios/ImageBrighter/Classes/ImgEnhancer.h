//
//  ImgEnhancer.h
//  HelloCordova
//
//  Created by Libin Varghese on 29/12/14.
//
//

#import <Cordova/CDV.h>

@interface ImgEnhancer : CDVPlugin

// Cordova command method
- (void) enhanceImageWithData: (CDVInvokedUrlCommand*) command;

- (void) didCancelImgEnhancer;
- (void) didCompleteImgEnhancerWithPath: (NSString *) path;

@end
