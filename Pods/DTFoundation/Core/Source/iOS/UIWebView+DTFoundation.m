//
//  UIWebView+DTFoundation.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 25.05.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "UIWebView+DTFoundation.h"

@implementation UIWebView (DTFoundation)

- (NSString *)documentTitle
{
	return [self stringByEvaluatingJavaScriptFromString:@"document.title"];
}

@end
