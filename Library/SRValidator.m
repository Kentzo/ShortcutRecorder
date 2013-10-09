//
//  SRValidator.h
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
//      Silvio Rizzi
//      Ilya Kulakov

#import "SRValidator.h"
#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"


@implementation SRValidator

- (instancetype)initWithDelegate:(NSObject<SRValidatorDelegate> *)aDelegate;
{
    self = [super init];

    if (self)
    {
        _delegate = aDelegate;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithDelegate:nil];
}


#pragma mark Methods

- (BOOL)isKeyComboTaken:(SRKeyCombo *)combo error:(NSError **)outError
{
    if ([self isKeyComboTakenInDelegate:combo error:outError])
        return YES;

    if ((![self.delegate respondsToSelector:@selector(shortcutValidatorShouldCheckSystemShortcuts:)] ||
         [self.delegate shortcutValidatorShouldCheckSystemShortcuts:self]) &&
        [self isKeyComboTakenInSystemShortcuts:combo error:outError])
    {
        return YES;
    }

    if ((![self.delegate respondsToSelector:@selector(shortcutValidatorShouldCheckMenu:)] ||
         [self.delegate shortcutValidatorShouldCheckMenu:self]) &&
        [self isKeyCombo:combo takenInMenu:[NSApp mainMenu] error:outError])
    {
        return YES;
    }

    return NO;
}

- (BOOL)isKeyComboTakenInDelegate:(SRKeyCombo *)combo error:(NSError **)outError
{
    if (self.delegate)
    {
        NSString *delegateReason = nil;
        if ([self.delegate respondsToSelector:@selector(shortcutValidator:isKeyComboTaken:reason:)] &&
            [self.delegate shortcutValidator:self
                             isKeyComboTaken:combo
                                      reason:&delegateReason])
        {
            if (outError)
            {
                BOOL isASCIIOnly = YES;

                if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                    isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode([combo modifiers], [combo keyCode]) : SRReadableStringForCocoaModifierFlagsAndKeyCode([combo modifiers], [combo keyCode]);
                NSString *failureReason = [NSString stringWithFormat:
                                           SRLoc(@"The key combination \"%@\" can't be used!"),
                                           shortcut];
                NSString *description = [NSString stringWithFormat:
                                         SRLoc(@"The key combination \"%@\" can't be used because %@."),
                                         shortcut,
                                         [delegateReason length] ? delegateReason : @"it's already used"];
                NSDictionary *userInfo = @{
                    NSLocalizedFailureReasonErrorKey : failureReason,
                    NSLocalizedDescriptionKey: description
                };
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
            }

            return YES;
        }
    }

    return NO;
}

- (BOOL)isKeyComboTakenInSystemShortcuts:(SRKeyCombo *)combo error:(NSError **)outError
{
    CFArrayRef s = NULL;
    OSStatus err = CopySymbolicHotKeys(&s);

    if (err != noErr)
        return YES;

    NSArray *symbolicHotKeys = (NSArray *)CFBridgingRelease(s);
    NSUInteger flags = [combo modifiers] & SRCocoaModifierFlagsMask;

    for (NSDictionary *symbolicHotKey in symbolicHotKeys)
    {
        if ((__bridge CFBooleanRef)symbolicHotKey[(__bridge NSString *)kHISymbolicHotKeyEnabled] != kCFBooleanTrue)
            continue;

        unsigned short symbolicHotKeyCode = [symbolicHotKey[(__bridge NSString *)kHISymbolicHotKeyCode] integerValue];

        if (symbolicHotKeyCode == [combo keyCode])
        {
            UInt32 symbolicHotKeyFlags = [symbolicHotKey[(__bridge NSString *)kHISymbolicHotKeyModifiers] unsignedIntValue];
            symbolicHotKeyFlags &= SRCarbonModifierFlagsMask;

            if (SRCarbonToCocoaFlags(symbolicHotKeyFlags) == flags)
            {
                if (outError)
                {
                    BOOL isASCIIOnly = YES;

                    if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                        isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                    NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode([combo modifiers], [combo keyCode]) : SRReadableStringForCocoaModifierFlagsAndKeyCode([combo modifiers], [combo keyCode]);
                    NSString *failureReason = [NSString stringWithFormat:
                                               SRLoc(@"The key combination \"%@\" can't be used!"),
                                               shortcut];
                    NSString *description = [NSString stringWithFormat:
                                             SRLoc(@"The key combination \"%@\" can't be used because it's already used by a system-wide keyboard shortcut. If you really want to use this key combination, most shortcuts can be changed in the Keyboard panel in System Preferences."),
                                             shortcut];
                    NSDictionary *userInfo = @{
                        NSLocalizedFailureReasonErrorKey: failureReason,
                        NSLocalizedDescriptionKey: description
                    };
                    *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
                }

                return YES;
            }
        }
    }

    return NO;
}

- (BOOL)isKeyCombo:(SRKeyCombo *)combo takenInMenu:(NSMenu *)aMenu error:(NSError **)outError
{
    NSUInteger flags = [combo modifiers] & SRCocoaModifierFlagsMask;

    for (NSMenuItem *menuItem in [aMenu itemArray])
    {
        if (menuItem.hasSubmenu && [self isKeyCombo:combo takenInMenu:menuItem.submenu error:outError])
            return YES;

        NSString *keyEquivalent = menuItem.keyEquivalent;

        if (![keyEquivalent length])
            continue;

        NSUInteger keyEquivalentModifierMask = menuItem.keyEquivalentModifierMask;

        if (SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags([combo keyCode], flags, keyEquivalent, keyEquivalentModifierMask))
        {
            if (outError)
            {
                BOOL isASCIIOnly = YES;

                if ([self.delegate respondsToSelector:@selector(shortcutValidatorShouldUseASCIIStringForKeyCodes:)])
                    isASCIIOnly = [self.delegate shortcutValidatorShouldUseASCIIStringForKeyCodes:self];

                NSString *shortcut = isASCIIOnly ? SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode([combo modifiers], [combo keyCode]) : SRReadableStringForCocoaModifierFlagsAndKeyCode([combo modifiers], [combo keyCode]);
                NSString *failureReason = [NSString stringWithFormat:SRLoc(@"The key combination \"%@\" can't be used!"), shortcut];
                NSString *description = [NSString stringWithFormat:SRLoc(@"The key combination \"%@\" can't be used because it's already used by the menu item \"%@\"."), shortcut, menuItem.SR_path];
                NSDictionary *userInfo = @{
                    NSLocalizedFailureReasonErrorKey: failureReason,
                    NSLocalizedDescriptionKey: description
                };
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
            }

            return YES;
        }
    }

    return NO;
}

@end


@implementation NSMenuItem (SRValidator)

- (NSString *)SR_path
{
    NSMutableArray *items = [NSMutableArray array];
    static const NSUInteger Limit = 1000;
    NSMenuItem *currentMenuItem = self;
    NSUInteger i = 0;

    do
    {
        [items insertObject:currentMenuItem atIndex:0];
        currentMenuItem = currentMenuItem.parentItem;
        ++i;
    }
    while (currentMenuItem && i < Limit);

    NSMutableString *path = [NSMutableString string];

    for (NSMenuItem *menuItem in items)
        [path appendFormat:@"%@➝", menuItem.title];

    if ([path length] > 1)
        [path deleteCharactersInRange:NSMakeRange([path length] - 1, 1)];

    return path;
}

@end
