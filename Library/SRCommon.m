//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim
//      Ilya Kulakov

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"


NSString *SRReadableStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, unsigned short aKeyCode)
{
    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedPlainTransformer];
    NSString *c = [t transformedValue:@(aKeyCode)];

    return [NSString stringWithFormat:@"%@%@%@%@%@",
                                      (aModifierFlags & NSCommandKeyMask ? SRLoc(@"Command-") : @""),
                                      (aModifierFlags & NSAlternateKeyMask ? SRLoc(@"Option-") : @""),
                                      (aModifierFlags & NSControlKeyMask ? SRLoc(@"Control-") : @""),
                                      (aModifierFlags & NSShiftKeyMask ? SRLoc(@"Shift-") : @""),
                                      c];
}


NSString *SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, unsigned short aKeyCode)
{
    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedPlainASCIITransformer];
    NSString *c = [t transformedValue:@(aKeyCode)];

    return [NSString stringWithFormat:@"%@%@%@%@%@",
            (aModifierFlags & NSCommandKeyMask ? SRLoc(@"Command-") : @""),
            (aModifierFlags & NSAlternateKeyMask ? SRLoc(@"Option-") : @""),
            (aModifierFlags & NSControlKeyMask ? SRLoc(@"Control-") : @""),
            (aModifierFlags & NSShiftKeyMask ? SRLoc(@"Shift-") : @""),
            c];
}


static BOOL _SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                             NSUInteger aKeyCodeFlags,
                                                             NSString *aKeyEquivalent,
                                                             NSUInteger aKeyEquivalentModifierFlags,
                                                             SRKeyCodeTransformer *aTransformer)
{
    if (!aKeyEquivalent)
        return NO;

    aKeyCodeFlags &= SRCocoaModifierFlagsMask;
    aKeyEquivalentModifierFlags &= SRCocoaModifierFlagsMask;

    if (aKeyCodeFlags == aKeyEquivalentModifierFlags)
    {
        NSString *keyCodeRepresentation = [aTransformer transformedValue:@(aKeyCode)
                                               withImplicitModifierFlags:nil
                                                   explicitModifierFlags:@(aKeyCodeFlags)];
        return [keyCodeRepresentation isEqual:aKeyEquivalent];
    }
    else if (!aKeyEquivalentModifierFlags ||
             (aKeyCodeFlags & aKeyEquivalentModifierFlags) == aKeyEquivalentModifierFlags)
    {
        // Some key equivalent modifier flags can be implicitly set by using special unicode characters. E.g. Œ insetead of opt-a.
        // However all modifier flags explictily set in key equivalent MUST be also set in key code flags.
        // E.g. ctrl-Œ/ctrl-opt-a and Œ/opt-a match this condition, but cmd-Œ/ctrl-opt-a doesn't.
        NSString *keyCodeRepresentation = [aTransformer transformedValue:@(aKeyCode)
                                               withImplicitModifierFlags:nil
                                                   explicitModifierFlags:@(aKeyCodeFlags)];

        if ([keyCodeRepresentation isEqual:aKeyEquivalent])
        {
            // Key code and key equivalent are not equal key code representation matches key equivalent, but modifier flags are not.
            return NO;
        }
        else
        {
            NSUInteger possiblyImplicitFlags = aKeyCodeFlags & ~aKeyEquivalentModifierFlags;
            keyCodeRepresentation = [aTransformer transformedValue:@(aKeyCode)
                                         withImplicitModifierFlags:@(possiblyImplicitFlags)
                                             explicitModifierFlags:@(aKeyEquivalentModifierFlags)];
            return [keyCodeRepresentation isEqual:aKeyEquivalent];
        }
    }
    else
        return NO;
}


BOOL SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                     NSUInteger aKeyCodeFlags,
                                                     NSString *aKeyEquivalent,
                                                     NSUInteger aKeyEquivalentModifierFlags)
{
    BOOL isEqual = _SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(aKeyCode,
                                                                    aKeyCodeFlags,
                                                                    aKeyEquivalent,
                                                                    aKeyEquivalentModifierFlags,
                                                                    [SRKeyCodeTransformer sharedASCIITransformer]);

    if (!isEqual)
    {
        isEqual = _SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(aKeyCode,
                                                                   aKeyCodeFlags,
                                                                   aKeyEquivalent,
                                                                   aKeyEquivalentModifierFlags,
                                                                   [SRKeyCodeTransformer sharedTransformer]);
    }

    return isEqual;
}
