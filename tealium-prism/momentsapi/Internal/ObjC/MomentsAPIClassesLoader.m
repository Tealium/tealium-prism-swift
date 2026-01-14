//
//  MomentsAPIClassesLoader.m
//  tealium-prism
//
//  Created by Sebastian Krajna on 25/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#import "MomentsAPIClassesLoader.h"

#if COCOAPODS
#if defined __has_include && __has_include(<TealiumPrism-Swift.h>)
#import <TealiumPrism-Swift.h>
#else
#import <TealiumPrism/TealiumPrism-Swift.h>
#endif
#else
#ifdef SWIFT_PACKAGE
@import TealiumPrismMomentsAPI;
#else
#import <TealiumPrismMomentsAPI/TealiumPrismMomentsAPI-Swift.h>
#endif
#endif

@implementation MomentsAPIClassesLoader

+(void)load {
    [MomentsAPIAutomaticLoader setup];
}

@end

