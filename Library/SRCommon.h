//
//  Copyright 2006 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 Mask representing subset of Cocoa modifier flags suitable for shortcuts.
 */
NS_SWIFT_NAME(CocoaModifierFlagsMask)
static const NSEventModifierFlags SRCocoaModifierFlagsMask = NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagShift | NSEventModifierFlagControl;


/*!
 Mask representing subset of Carbon modifier flags suitable for shortcuts.
 */
NS_SWIFT_NAME(CarbonModifierFlagsMask)
static const UInt32 SRCarbonModifierFlagsMask = cmdKey | optionKey | shiftKey | controlKey;


/*!
 Dawable unicode characters for key codes that do not have appropriate constants in Carbon and Cocoa.

 @seealso SRKeyCodeString
 */
typedef NS_ENUM(unichar, SRKeyCodeGlyph)
{
    SRKeyCodeGlyphTabRight = 0x21E5, // ⇥
    SRKeyCodeGlyphTabLeft = 0x21E4, // ⇤
    SRKeyCodeGlyphReturn = 0x2305, // ⌅
    SRKeyCodeGlyphReturnR2L = 0x21A9, // ↩
    SRKeyCodeGlyphDeleteLeft = 0x232B, // ⌫
    SRKeyCodeGlyphDeleteRight = 0x2326, // ⌦
    SRKeyCodeGlyphPadClear = 0x2327, // ⌧
    SRKeyCodeGlyphLeftArrow = 0x2190, // ←
    SRKeyCodeGlyphRightArrow = 0x2192, // →
    SRKeyCodeGlyphUpArrow = 0x2191, // ↑
    SRKeyCodeGlyphDownArrow = 0x2193, // ↓
    SRKeyCodeGlyphPageDown = 0x21DF, // ⇟
    SRKeyCodeGlyphPageUp = 0x21DE, // ⇞
    SRKeyCodeGlyphNorthwestArrow = 0x2196, // ↖
    SRKeyCodeGlyphSoutheastArrow = 0x2198, // ↘
    SRKeyCodeGlyphEscape = 0x238B, // ⎋
    SRKeyCodeGlyphSpace = 0x0020, // ' '
    SRKeyCodeGlyphJISUnderscore = 0xFF3F, // ＿
    SRKeyCodeGlyphJISComma = 0x3001, // 、
    SRKeyCodeGlyphJISYen = 0x00A5, // ¥
    SRKeyCodeGlyphANSI0 = 0x30, // 0
    SRKeyCodeGlyphANSI1 = 0x31, // 1
    SRKeyCodeGlyphANSI2 = 0x32, // 2
    SRKeyCodeGlyphANSI3 = 0x33, // 3
    SRKeyCodeGlyphANSI4 = 0x34, // 4
    SRKeyCodeGlyphANSI5 = 0x35, // 5
    SRKeyCodeGlyphANSI6 = 0x36, // 6
    SRKeyCodeGlyphANSI7 = 0x37, // 7
    SRKeyCodeGlyphANSI8 = 0x38, // 8
    SRKeyCodeGlyphANSI9 = 0x39, // 9
    SRKeyCodeGlyphANSIEqual = 0x3d, // =
    SRKeyCodeGlyphANSIMinus = 0x2d, // -
    SRKeyCodeGlyphANSISlash = 0x2f, // /
    SRKeyCodeGlyphANSIPeriod = 0x2e // .
} NS_SWIFT_NAME(KeyCodeGlyph);


/*!
 NSString version of SRKeyCodeGlyph

 @seealso SRKeyCodeGlyph
 */
typedef NSString *SRKeyCodeString NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(KeyCodeString);
extern SRKeyCodeString const SRKeyCodeStringTabRight;
extern SRKeyCodeString const SRKeyCodeStringTabLeft;
extern SRKeyCodeString const SRKeyCodeStringReturn;
extern SRKeyCodeString const SRKeyCodeStringReturnR2L;
extern SRKeyCodeString const SRKeyCodeStringDeleteLeft;
extern SRKeyCodeString const SRKeyCodeStringDeleteRight;
extern SRKeyCodeString const SRKeyCodeStringPadClear;
extern SRKeyCodeString const SRKeyCodeStringLeftArrow;
extern SRKeyCodeString const SRKeyCodeStringRightArrow;
extern SRKeyCodeString const SRKeyCodeStringUpArrow;
extern SRKeyCodeString const SRKeyCodeStringDownArrow;
extern SRKeyCodeString const SRKeyCodeStringPageDown;
extern SRKeyCodeString const SRKeyCodeStringPageUp;
extern SRKeyCodeString const SRKeyCodeStringNorthwestArrow;
extern SRKeyCodeString const SRKeyCodeStringSoutheastArrow;
extern SRKeyCodeString const SRKeyCodeStringEscape;
extern SRKeyCodeString const SRKeyCodeStringSpace;
extern SRKeyCodeString const SRKeyCodeStringHelp;
extern SRKeyCodeString const SRKeyCodeStringJISUnderscore;
extern SRKeyCodeString const SRKeyCodeStringJISComma;
extern SRKeyCodeString const SRKeyCodeStringJISYen;


/*!
 Dawable unicode characters for modifier flags.

 @seealso SRModifierFlagString
 */
typedef NS_ENUM(unichar, SRModifierFlagGlyph)
{
    SRModifierFlagGlyphCommand = kCommandUnicode, // ⌘
    SRModifierFlagGlyphOption = kOptionUnicode,  // ⌥
    SRModifierFlagGlyphShift = kShiftUnicode, // ⇧
    SRModifierFlagGlyphControl = kControlUnicode // ⌃
} NS_SWIFT_NAME(ModifierFlagGlyph);


/*!
 NSString version of SRModifierFlagGlyph

 @seealso SRModifierFlagGlyph
 */
typedef NSString *SRModifierFlagString NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ModifierFlagString);
extern SRModifierFlagString const SRModifierFlagStringCommand;
extern SRModifierFlagString const SRModifierFlagStringOption;
extern SRModifierFlagString const SRModifierFlagStringShift;
extern SRModifierFlagString const SRModifierFlagStringControl;


/*!
 Convert a unichar literal into a NSString.
 */
NS_SWIFT_NAME(unicharToString(_:))
NS_INLINE NSString * SRUnicharToString(unichar aChar)
{
    return [NSString stringWithFormat:@"%C", aChar];
}


/*!
 Convert Carbon modifier flags to Cocoa.
 */
NS_SWIFT_NAME(carbonToCocoaFlags(_:))
NS_INLINE NSEventModifierFlags SRCarbonToCocoaFlags(UInt32 aCarbonFlags)
{
    NSEventModifierFlags cocoaFlags = 0;

    if (aCarbonFlags & cmdKey)
        cocoaFlags |= NSEventModifierFlagCommand;

    if (aCarbonFlags & optionKey)
        cocoaFlags |= NSEventModifierFlagOption;

    if (aCarbonFlags & controlKey)
        cocoaFlags |= NSEventModifierFlagControl;

    if (aCarbonFlags & shiftKey)
        cocoaFlags |= NSEventModifierFlagShift;

    return cocoaFlags;
}

/*!
 Convert Cocoa modifier flags to Carbon.
 */
NS_SWIFT_NAME(cocoaToCarbonFlags(_:))
NS_INLINE UInt32 SRCocoaToCarbonFlags(NSEventModifierFlags aCocoaFlags)
{
    UInt32 carbonFlags = 0;

    if (aCocoaFlags & NSEventModifierFlagCommand)
        carbonFlags |= cmdKey;

    if (aCocoaFlags & NSEventModifierFlagOption)
        carbonFlags |= optionKey;

    if (aCocoaFlags & NSEventModifierFlagControl)
        carbonFlags |= controlKey;

    if (aCocoaFlags & NSEventModifierFlagShift)
        carbonFlags |= shiftKey;

    return carbonFlags;
}


/*!
 Return Bundle where resources can be found.

 @throws NSInternalInconsistencyException

 @discussion Throws NSInternalInconsistencyException if bundle cannot be found.
 */
NS_SWIFT_NAME(shortcutRecorderBundle())
NSBundle * SRBundle(void);


/*!
 Convenience method to get localized string from the framework bundle.
 */
NS_SWIFT_NAME(shortcutRecorderLocalizedString(forKey:))
NSString * SRLoc(NSString * _Nullable aKey) __attribute__((annotate("returns_localized_nsstring")));


/*!
 Convenience method to get image from the framework bundle.
 */
NS_SWIFT_NAME(shortcutRecorderImage(forResource:))
NSImage * _Nullable SRImage(NSString * _Nullable anImageName);


@interface NSObject (SRCommon)

/*!
 Uses -isEqual: of the most specialized class of the same hierarchy to maintain transitivity and associativity.

 In the root class that overrides -isEqual:

 - (BOOL)isEqualTo<Class>:(<Class> *)anObject
 {
     if (anObject == self)
         return YES;
     else if (![anObject isKindOfClass:<Class>.class])
         return NO;
     else
         return <memberwise comparison>;
 }

 - (BOOL)isEqual:(NSObject *)anObject
 {
     return [self SR_isEqual:anObject usingSelector:@selector(isEqualTo<Class>:) ofCommonAncestor:<Class>.class];
 }

 In subsequent subclasses of the root class that extend equality test:

 - (BOOL)isEqualTo<Class>:(<Class> *)anObject
 {
     if (anObject == self)
         return YES;
     else if (![anObject isKindOfClass:self.class])
         return NO;
     else if (![super isEqualTo<Class>:anObject])
         return NO;
     else
         return <memberwise comparison>;
 }
 */
- (BOOL)SR_isEqual:(nullable NSObject *)anObject usingSelector:(SEL)aSelector ofCommonAncestor:(Class)anAncestor;

@end

NS_ASSUME_NONNULL_END
