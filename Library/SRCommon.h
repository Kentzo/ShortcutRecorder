//
//  SRCommon.h
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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


/*!
    @brief  Mask representing subset of Cocoa modifier flags suitable for shortcuts.
 */
static const NSUInteger SRCocoaModifierFlagsMask = NSCommandKeyMask | NSAlternateKeyMask | NSShiftKeyMask | NSControlKeyMask;

/*!
    @brief  Mask representing subset of Carbon modifier flags suitable for shortcuts.
 */
static const NSUInteger SRCarbonModifierFlagsMask = cmdKey | optionKey | shiftKey | controlKey;


/*!
    @brief  Converts carbon modifier flags to cocoa.
 */
FOUNDATION_STATIC_INLINE NSUInteger SRCarbonToCocoaFlags(UInt32 aCarbonFlags)
{
    NSUInteger cocoaFlags = 0;

    if (aCarbonFlags & cmdKey)
        cocoaFlags |= NSCommandKeyMask;

    if (aCarbonFlags & optionKey)
        cocoaFlags |= NSAlternateKeyMask;

    if (aCarbonFlags & controlKey)
        cocoaFlags |= NSControlKeyMask;

    if (aCarbonFlags & shiftKey)
        cocoaFlags |= NSShiftKeyMask;

    return cocoaFlags;
}

/*!
    @brief  Converts cocoa modifier flags to carbon.
 */
FOUNDATION_STATIC_INLINE UInt32 SRCocoaToCarbonFlags(NSUInteger aCocoaFlags)
{
    UInt32 carbonFlags = 0;

    if (aCocoaFlags & NSCommandKeyMask)
        carbonFlags |= cmdKey;

    if (aCocoaFlags & NSAlternateKeyMask)
        carbonFlags |= optionKey;

    if (aCocoaFlags & NSControlKeyMask)
        carbonFlags |= controlKey;

    if (aCocoaFlags & NSShiftKeyMask)
        carbonFlags |= shiftKey;

    return carbonFlags;
}

/*!
    @brief  Convenient method to get localized string from the framework bundle.
 */
FOUNDATION_STATIC_INLINE NSString *SRLoc(NSString *aKey)
{
    return NSLocalizedStringFromTableInBundle(aKey,
                                              @"ShortcutRecorder",
                                              [NSBundle bundleWithIdentifier:@"com.kulakov.ShortcutRecorder"],
                                              nil);
}


/*!
    @brief  Convenient method to get image from the framework bundle.
 */
FOUNDATION_STATIC_INLINE NSImage *SRImage(NSString *anImageName)
{
    NSBundle *b = [NSBundle bundleWithIdentifier:@"com.kulakov.ShortcutRecorder"];

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        return [[NSImage alloc] initByReferencingURL:[b URLForImageResource:anImageName]];
    else
        return [b imageForResource:anImageName];
}


/*!
    @brief  Returns string representation of shortcut with modifier flags replaced with their localized
            readable equivalents (e.g. ? -> Option).
 */
NSString *SRReadableStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, unsigned short aKeyCode);

/*!
    @brief  Returns string representation of shortcut with modifier flags replaced with their localized
            readable equivalents (e.g. ? -> Option) and ASCII character for key code.
 */
NSString *SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, unsigned short aKeyCode);

/*!
    @brief      Determines if given key code with flags is equal to key equivalent and flags
                (usually taken from NSButton or NSMenu).

    @discussion On Mac OS X some key combinations can have "alternates". E.g. option-A can be represented both as option-A and as Œ.
*/
BOOL SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                     NSUInteger aKeyCodeFlags,
                                                     NSString *aKeyEquivalent,
                                                     NSUInteger aKeyEquivalentModifierFlags);
