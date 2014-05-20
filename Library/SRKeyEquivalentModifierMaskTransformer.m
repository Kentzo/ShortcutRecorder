//
//  SRKeyEquivalentModifierMaskTransformer.m
//  ShortcutRecorder
//
//  Copyright 2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import "SRKeyEquivalentModifierMaskTransformer.h"
#import "SRKeyCodeTransformer.h"
#import "SRRecorderControl.h"


@implementation SRKeyEquivalentModifierMaskTransformer

#pragma mark NSValueTransformer

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

- (NSNumber *)transformedValue:(id)shortcut
{
    if ([shortcut isKindOfClass:[NSDictionary class]]) {
        shortcut = [SRShortcut shortcutWithDictionaryRepresentation:shortcut];
    }

    return @([shortcut modifiers]);
}

@end
