//
//  LifecycleObservableLoader.m
//  tealium-prism
//
//  Created by Denis Guzov on 02/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#import "SwiftClassesLoader.h"
#if TARGET_OS_IOS

#if COCOAPODS
#if defined __has_include && __has_include(<TealiumPrism-Swift.h>)
#import <TealiumPrism-Swift.h>
#else
#import <TealiumPrism/TealiumPrism-Swift.h>
#endif
#else
#ifdef SWIFT_PACKAGE
@import TealiumCore;
#else
#import <TealiumCore/TealiumCore-Swift.h>
#endif
#endif

@implementation SwiftClassesLoader

+(void)load {
    [ApplicationStatusListener setup];
    [TealiumDelegateProxy setup];
}

@end
#endif
