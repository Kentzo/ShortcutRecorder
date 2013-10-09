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

- (NSNumber *)transformedValue:(id)keyCombo
{
    if ([keyCombo isKindOfClass:[NSDictionary class]]) {
        keyCombo = [SRKeyCombo keyComboWithDictionaryRepresentation:keyCombo];
    }

    return @([keyCombo modifiers]);
}

@end
