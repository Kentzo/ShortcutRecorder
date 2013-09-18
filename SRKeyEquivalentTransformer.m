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

- (NSString *)transformedValue:(SRKeyCombo *)keyCombo
{
    if (keyCombo) {
        SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedASCIITransformer];
        return [t transformedValue:@([keyCombo keyCode])
            withImplicitModifierFlags:nil
            explicitModifierFlags:@([keyCombo modifiers])];
    } else {
        return nil;
    }
}

@end
