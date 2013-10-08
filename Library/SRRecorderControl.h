//
//  SRRecorderControl.h
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
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRCommon.h>


/*!
    @brief      Key code.

    @discussion NSNumber representation of unsigned short.
                Required key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutKeyCode;

/*!
    @brief      Modifier flags.

    @discussion NSNumber representation of NSUInteger.
                Optional key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutModifierFlagsKey;

/*!
    @brief      Interpretation of key code and modifier flags depending on system locale and input source
                used when shortcut was taken.

    @discussion NSString.
                Optional key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutCharacters;

/*!
    @brief      Interpretation of key code without modifier flags depending on system locale and input source
                used when shortcut was taken.

    @discussion NSString.
                Optional key of SRRecorderControl's objectValue.
 */
extern NSString *const SRShortcutCharactersIgnoringModifiers;


@protocol SRRecorderControlDelegate;


/*!
    @brief      An SRRecorderControl object is a control (but not a subclass of NSControl) that allows you to record shortcuts.

    @discussion In addition to NSView bindings, exposes:
                NSValueBinding. This binding supports 2 options:
                    - NSValueTransformerBindingOption
                    - NSValueTransformerNameBindingOption
                NSEnabledBinding. This binding supports 2 options:
                    - NSValueTransformerBindingOption
                    - NSValueTransformerNameBindingOption
                    Note that at that moment, this binding _is not_ multivalue.

                Required height: 25 points
                Recommended min width: 100 points
 */
@interface SRRecorderControl : NSView /* <NSAccessibility, NSKeyValueBindingCreation, NSToolTipOwner> */

/*!
    @brief      The receiver’s delegate.

    @discussion A recorder control delegate responds to editing-related messages. You can use to to prevent editing
                in some cases or to validate typed shortcuts.
 */
@property (assign) IBOutlet NSObject<SRRecorderControlDelegate> *delegate;

/*!
    @brief      Returns an integer bit field indicating allowed modifier flags.

    @discussion Defaults to SRCocoaModifierFlagsMask.
 */
@property (readonly) NSUInteger allowedModifierFlags;

/*!
    @brief      Returns an integer bit field indicating required modifier flags.

    @discussion Defaults to 0.
 */
@property (readonly) NSUInteger requiredModifierFlags;

/*!
    @brief      Determines whether shortcuts without modifier flags are allowed.

    @discussion Defaults to NO.
 */
@property (readonly) BOOL allowsEmptyModifierFlags;

/*!
    @brief      Determines whether the control reinterpret key code and modifier flags
                using ASCII capable input source.

    @discussion Defaults to YES.
                If not set, the same key code may be draw differently depending on current input source.
                E.g. with US English input source key code 0x0 is interpreted as "a",
                however with Russian input source, it's interpreted as "ф".
 */
@property BOOL drawsASCIIEquivalentOfShortcut;

/*!
    @brief      Determines whether Escape is used to cancel recording.

    @discussion Defaults to YES.
                If set, Escape without modifier flags cannot be recorded as shortcut.
 */
@property BOOL allowsEscapeToCancelRecording;

/*!
    @brief      Determines whether delete (or forward delete) is used to remove current shortcut and end recording.

    @discussion Defaults to YES.
                If set, neither Delete nor Forward Delete without modifier flags can be recorded as shortcut.
 */
@property BOOL allowsDeleteToClearShortcutAndEndRecording;

/*!
    @brief  Determines whether control enabled and can be edited or not.

    @discussion Defaults to YES.
 */
@property (nonatomic, getter=isEnabled) BOOL enabled;

/*!
    @brief  Determines whether recording is in process.
 */
@property (nonatomic, readonly) BOOL isRecording;

/*!
    @brief  Returns dictionary representation of receiver's shortcut.
 */
@property (nonatomic, copy) NSDictionary *objectValue;

/*!
    @brief      Configures recording behavior of the control.

    @param      newAllowedModifierFlags New allowed modifier flags.

    @param      newRequiredModifierFlags New required modifier flags.

    @param      newAllowsEmptyModifierFlags Determines whether empty modifier flags are allowed.

    @discussion Flags are filtered using SRCocoaModifierFlagsMask. Flags does not affect object values set manually.

                These restrictions can be ignored if delegate implements shortcutRecorder:shouldUnconditionallyAllowModifierFlags:forKeyCode: and returns YES for given modifier flags and key code.

                Throws NSInvalidArgumentException if either required flags are not allowed
                or required flags are not empty and no modifier flags are allowed.

    @see        SRRecorderControlDelegate
 */
- (void)setAllowedModifierFlags:(NSUInteger)newAllowedModifierFlags
          requiredModifierFlags:(NSUInteger)newRequiredModifierFlags
       allowsEmptyModifierFlags:(BOOL)newAllowsEmptyModifierFlags;

/*!
    @brief      Turns on the recording mode.

    @discussion You SHOULD not call this method directly.
 */
- (BOOL)beginRecording;

/*!
    @brief      Turns off the recording mode. Current object value is preserved.

    @discussion You SHOULD not call this method directly.
 */
- (void)endRecording;

/*!
    @brief      Clears object value and turns off the recording mode.

    @discussion You SHOULD not call this method directly.
 */
- (void)clearAndEndRecording;

/*!
    @brief      Designated method to end recording. Sets a given object value, updates bindings and turns off the recording mode.

    @discussion You SHOULD not call this method directly.
 */
- (void)endRecordingWithObjectValue:(NSDictionary *)anObjectValue;


/*!
    @brief      Returns shape of the control.

    @discussion Primarily used to draw appropriate focus ring.
 */
- (NSBezierPath *)controlShape;

/*!
    @brief  Returns rect for label with given attributes.

    @param  aLabel Label for drawing.

    @param  anAttributes A dictionary of NSAttributedString text attributes to be applied to the string.
 */
- (NSRect)rectForLabel:(NSString *)aLabel withAttributes:(NSDictionary *)anAttributes;

/*!
    @brief  Returns rect of the snap back button in the receiver coordinates.
 */
- (NSRect)snapBackButtonRect;

/*!
    @brief      Returns rect of the clear button in the receiver coordinates.

    @discussion Returned rect will have empty width (other values will be valid) if button should not be drawn.
 */
- (NSRect)clearButtonRect;


/*!
    @brief      Returns label to be displayed by the receiver.

    @discussion Returned value depends on isRecording state objectValue and currenlty pressed keys and modifier flags.
 */
- (NSString *)label;

/*!
    @brief      Returns label for accessibility.

    @discussion Returned value depends on isRecording state objectValue and currenlty pressed keys and modifier flags.
 */
- (NSString *)accessibilityLabel;

/*!
    @brief      Returns string representation of object value.
 */
- (NSString *)stringValue;

/*!
    @brief      Returns string representation of object value for accessibility.
 */
- (NSString *)accessibilityStringValue;

/*!
    @brief      Returns attirbutes of label to be displayed by the receiver according to current state.

    @see        normalLabelAttributes

    @see        recordingLabelAttributes

    @see        disabledLabelAttributes
 */
- (NSDictionary *)labelAttributes;

/*!
    @brief  Returns attributes of label to be displayed by the receiver in normal mode.
 */
- (NSDictionary *)normalLabelAttributes;

/*!
    @brief  Returns attributes of label to be displayed by the receiver in recording mode.
 */
- (NSDictionary *)recordingLabelAttributes;

/*!
    @brief  Returns attributes of label to be displayed by the receiver in disabled mode.
 */
- (NSDictionary *)disabledLabelAttributes;


/*!
    @brief  Draws background of the receiver into current graphics context.
 */
- (void)drawBackground:(NSRect)aDirtyRect;

/*!
    @brief  Draws interior of the receiver into current graphics context.
 */
- (void)drawInterior:(NSRect)aDirtyRect;

/*!
    @brief  Draws label of the receiver into current graphics context.
 */
- (void)drawLabel:(NSRect)aDirtyRect;

/*!
    @brief  Draws snap back button of the receiver into current graphics context.
 */
- (void)drawSnapBackButton:(NSRect)aDirtyRect;

/*!
    @brief  Draws clear button of the receiver into current graphics context.
 */
- (void)drawClearButton:(NSRect)aDirtyRect;


/*!
    @brief  Determines whether main button (representation of the receiver in normal mode) is highlighted.
 */
- (BOOL)isMainButtonHighlighted;

/*!
    @brief  Determines whether snap back button is highlighted.
 */
- (BOOL)isSnapBackButtonHighlighted;

/*!
    @brief  Determines whetehr clear button is highlighted.
 */
- (BOOL)isClearButtonHighlighted;

/*!
    @brief  Determines whether modifier flags are valid for key code according to the receiver settings.

    @param      aModifierFlags Proposed modifier flags.

    @param      aKeyCode Code of the pressed key.

    @see    allowedModifierFlags

    @see    allowsEmptyModifierFlags

    @see    requiredModifierFlags
 */
- (BOOL)areModifierFlagsValid:(NSUInteger)aModifierFlags forKeyCode:(unsigned short)aKeyCode;

/*!
    @brief A helper method to propagate view-driven changes back to model.
 
    @discussion This method makes it easier to propagate changes from a view
                back to the model without overriding bind:toObject:withKeyPath:options:
 
    @see        http://tomdalling.com/blog/cocoa/implementing-your-own-cocoa-bindings/
 */
- (void)propagateValue:(id)aValue forBinding:(NSString *)aBinding;

@end


@protocol SRRecorderControlDelegate <NSObject>

@optional

/*!
    @brief      Asks the delegate if editing should begin in the specified shortcut recorder.

    @param      aRecorder The shortcut recorder which editing is about to begin.

    @result     YES if an editing session should be initiated; otherwise, NO to disallow editing.

    @discussion Implementation of this method by the delegate is optional. If it is not present, editing proceeds as if this method had returned YES.
 */
- (BOOL)shortcutRecorderShouldBeginRecording:(SRRecorderControl *)aRecorder;

/*!
    @brief      Gives a delegate opportunity to bypass rules specified by allowed and required modifier flags.

    @param      aRecorder The shortcut recorder for which editing ended.

    @param      aModifierFlags Proposed modifier flags.

    @param      aKeyCode Code of the pressed key.

    @result     YES if recorder should bypass key code with given modifier flags despite settings like required modifier flags, allowed modifier flags.

    @discussion Implementation of this method by the delegate is optional.
                Normally, you wouldn't allow a user to record shourcut without modifier flags set: disallow 'a', but allow cmd-'a'.
                However, some keys were designed to be key shortcuts by itself. E.g. Functional keys. By implementing this method a delegate can allow
                these special keys to be set without modifier flags even when the control is configured to disallow empty modifier flags.

    @see    allowedModifierFlags

    @see    allowsEmptyModifierFlags

    @see    requiredModifierFlags
 */
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder shouldUnconditionallyAllowModifierFlags:(NSUInteger)aModifierFlags forKeyCode:(unsigned short)aKeyCode;

/*!
    @brief      Asks the delegate if the shortcut can be set by the specified shortcut recorder.

    @param      aRecorder The shortcut recorder which shortcut is beign to be recordered.

    @param      aShortcut The Shortcut user typed.

    @result     YES if shortcut can be recordered. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, shortcut is recordered as if this method had returned YES.
                You may implement this method to filter shortcuts that were already set by other recorders.

    @see        SRValidator
 */
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder canRecordShortcut:(NSDictionary *)aShortcut;

/*!
    @brief      Tells the delegate that editing stopped for the specified shortcut recorder.

    @param      aRecorder The shortcut recorder for which editing ended.

    @discussion Implementation of this method by the delegate is optional.
 */
- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder;

@end


FOUNDATION_STATIC_INLINE BOOL SRShortcutEqualToShortcut(NSDictionary *a, NSDictionary *b)
{
    if (a == b)
        return YES;
    else if (a && !b)
        return NO;
    else if (!a && b)
        return NO;
    else
        return ([a[SRShortcutKeyCode] isEqual:b[SRShortcutKeyCode]] && [a[SRShortcutModifierFlagsKey] isEqual:b[SRShortcutModifierFlagsKey]]);
}


FOUNDATION_STATIC_INLINE NSDictionary *SRShortcutWithCocoaModifierFlagsAndKeyCode(NSUInteger aModifierFlags, unsigned short aKeyCode)
{
    return @{SRShortcutKeyCode: @(aKeyCode), SRShortcutModifierFlagsKey: @(aModifierFlags)};
}
