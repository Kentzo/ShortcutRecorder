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

- (NSString *)transformedValue:(id)keyCombo
{
    if ([keyCombo isKindOfClass:[NSDictionary class]]) {
        keyCombo = [SRKeyCombo keyComboWithDictionaryRepresentation:keyCombo];
    }

    if (keyCombo) {
        SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedASCIITransformer];
        return [t transformedValue:@([(SRKeyCombo*)keyCombo keyCode])
         withImplicitModifierFlags:nil
             explicitModifierFlags:@([(SRKeyCombo*)keyCombo modifiers])];
    } else {
        return @"";
    }
}

@end
