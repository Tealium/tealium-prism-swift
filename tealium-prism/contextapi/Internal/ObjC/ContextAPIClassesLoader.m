//
//  ContextAPIClassesLoader.m
//  tealium-prism
//
//  Created by Sebastian Krajna on 25/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#import "ContextAPIClassesLoader.h"

#if COCOAPODS
#if defined __has_include && __has_include(<TealiumPrism-Swift.h>)
#import <TealiumPrism-Swift.h>
#else
#import <TealiumPrism/TealiumPrism-Swift.h>
#endif
#else
#ifdef SWIFT_PACKAGE
@import TealiumPrismContextAPI;
#else
#import <TealiumPrismContextAPI/TealiumPrismContextAPI-Swift.h>
#endif
#endif

@implementation ContextAPIClassesLoader

+(void)load {
    [ContextAPIAutomaticLoader setup];
}

@end

