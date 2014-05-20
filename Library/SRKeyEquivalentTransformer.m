//
//  SRKeyEquivalentTransformer.m
//  ShortcutRecorder
//
//  Copyright 2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRKeyEquivalentTransformer.h"
#import "SRKeyCodeTransformer.h"
#import "SRRecorderControl.h"


@implementation SRKeyEquivalentTransformer

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [NSString class];
}

- (NSString *)transformedValue:(id)shortcut
{
    if ([shortcut isKindOfClass:[NSDictionary class]]) {
        shortcut = [SRShortcut shortcutWithDictionaryRepresentation:shortcut];
    }

    if (shortcut) {
        SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedASCIITransformer];
        return [t transformedValue:@([(SRShortcut*)shortcut keyCode])
         withImplicitModifierFlags:nil
             explicitModifierFlags:@([(SRShortcut*)shortcut modifiers])];
    } else {
        return @"";
    }
}

@end
