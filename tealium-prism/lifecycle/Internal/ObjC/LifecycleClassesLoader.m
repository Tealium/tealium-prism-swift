//
//  LifecycleClassesLoader.m
//  tealium-prism
//
//  Created by Enrico Zannini on 06/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#import "LifecycleClassesLoader.h"

#if COCOAPODS
#if defined __has_include && __has_include(<TealiumPrism-Swift.h>)
#import <TealiumPrism-Swift.h>
#else
#import <TealiumPrism/TealiumPrism-Swift.h>
#endif
#else
#ifdef SWIFT_PACKAGE
@import TealiumPrismLifecycle;
#else
#import <TealiumPrismLifecycle/TealiumPrismLifecycle-Swift.h>
#endif
#endif

@implementation LifecycleClassesLoader

+(void)load {
    [LifecycleAutomaticLoader setup];
}

@end
