//
//  JavaScriptTransformerClassesLoader.m
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#import "JavaScriptTransformerClassesLoader.h"

#if COCOAPODS
#if defined __has_include && __has_include(<TealiumPrism-Swift.h>)
#import <TealiumPrism-Swift.h>
#else
#import <TealiumPrism/TealiumPrism-Swift.h>
#endif
#else
#ifdef SWIFT_PACKAGE
@import TealiumPrismJavaScriptTransformer;
#else
#import <TealiumPrismJavaScriptTransformer/TealiumPrismJavaScriptTransformer-Swift.h>
#endif
#endif
#if !TARGET_OS_WATCH
@implementation JavaScriptTransformerClassesLoader

+(void)load {
    [JavaScriptTransformerAutomaticLoader setup];
}

@end
#endif
