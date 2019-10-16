//
//  Copyright 2006 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRCommon.h>
#import <ShortcutRecorder/SRShortcut.h>
#import <ShortcutRecorder/SRRecorderControlStyle.h>

@protocol SRRecorderControlDelegate;


NS_ASSUME_NONNULL_BEGIN

/*!
 SRRecorderControl is a control that can record keyboard shortcuts.

 @discussion
 NSValueBinding is supported with the following options:
 - NSValueTransformerBindingOption
 - NSValueTransformerNameBindingOption
 This binding is not a multivalue.

 The control conforms to NSEditor. If object bound to NSValueBinding
 also conforms to NSEditorRegistration appropriate methods will be called.

 NSControl
 - There is no cell
 - The value can only be changed via objectValue other value setters are ignored
 - Text formatting is ignored, override -drawingLabel instead
 - There is no NSText field editor; -abortEditing is an alias for -endRecording
 - Target/Action is respected and a notification is sent when recording ends
 - The -refusesFirstResponder property is respected
 - Considers delegate's -control:isValidObject:

 @note See objectValue for Shortcut Recorder 2 compatibility notes.
 */
NS_SWIFT_NAME(RecorderControl)
IB_DESIGNABLE
@interface SRRecorderControl : NSControl <NSAccessibilityButton, NSEditor, NSViewToolTipOwner> /* <NSNibLoading, NSKeyValueBindingCreation> */
{
    BOOL _isCompatibilityModeEnabled;
}

/*!
 Called by a designated initializer to set up internal state.
 */
- (void)initInternalState;

#pragma mark Behavior

/*!
 The receiver’s delegate.

 @seealso SRRecorderControlDelegate
 */
@property (nullable, weak) IBOutlet NSObject<SRRecorderControlDelegate> *delegate;

/*!
 Return an integer bit field indicating allowed modifier flags.

 @discussion Defaults to SRCocoaModifierFlagsMask.
 */
@property (readonly) IBInspectable NSEventModifierFlags allowedModifierFlags;

/*!
 Return an integer bit field indicating required modifier flags.

 @discussion Defaults to 0.
 */
@property (readonly) IBInspectable NSEventModifierFlags requiredModifierFlags;

/*!
 Whether shortcuts without modifier flags are allowed.

 @discussion Defaults to NO.
 */
@property (readonly) IBInspectable BOOL allowsEmptyModifierFlags;

/*!
 Whether the control reinterpret key code and modifier flags using ASCII capable input source.

 @discussion
 Defaults to YES.
 If not set, the same key code may draw differently depending on current input source.
 E.g. with US English input source key code 0x0 is interpreted as "a",
 but with Russian input source it's interpreted as "ф".
 */
@property IBInspectable BOOL drawsASCIIEquivalentOfShortcut;

/*!
 Whether Escape is used to cancel recording.

 @discussion
 Defaults to YES.
 If set, Escape cannot be recorded without modifier flags.
 */
@property IBInspectable BOOL allowsEscapeToCancelRecording;

/*!
 Whether delete (or forward delete) is used to remove current shortcut and end recording.

 @discussion
 Defaults to YES.
 If set, neither Delete nor Forward Delete can be recorded without modifier flags.
 */
@property IBInspectable BOOL allowsDeleteToClearShortcutAndEndRecording;

/*!
 If YES, the shared global shortcut monitor is paused for the duration of the recording.

 @discussion
 Defaults to YES.

 @seealso SRShortcutAction
 */
@property IBInspectable BOOL pausesGlobalShortcutMonitorWhileRecording;

/*!
 Whether the string value respects the user interface layout direction.

 @discussion
 Defaults to NO.

 The control fully supports right-to-left layouts but macOS is inconsistent. Parts of the system
 draw key equivalents fully right-to-left, that is flags in reverse order and properly
 altered directional keys such as Tab. Yet other parts either support it only partially or not at all.
 The most visible key equivalents, those that appear in NSMenuItem, do not respect right-to-left at all.
 */
@property IBInspectable BOOL stringValueRespectsUserInterfaceLayoutDirection;

/*!
 Configure allowed and required modifier flags for user interaction.

 @param newAllowedModifierFlags New allowed modifier flags.

 @param newRequiredModifierFlags New required modifier flags.

 @param newAllowsEmptyModifierFlags Determines whether empty modifier flags are allowed.

 @discussion
 These restrictions can be ignored in delegate's -recorderControl:shouldUnconditionallyAllowModifierFlags:forKeyCode:

 @note Setting objectValue bypasses checks.

 @seealso SRRecorderControlDelegate
 */
- (void)setAllowedModifierFlags:(NSEventModifierFlags)newAllowedModifierFlags
          requiredModifierFlags:(NSEventModifierFlags)newRequiredModifierFlags
       allowsEmptyModifierFlags:(BOOL)newAllowsEmptyModifierFlags NS_SWIFT_NAME(set(allowedModifierFlags:requiredModifierFlags:allowsEmptyModifierFlags:));

/*!
 Check whether a given combination is valid.

 @param  aModifierFlags Proposed modifier flags.

 @param  aKeyCode Code of the pressed key.

 @seealso allowedModifierFlags

 @seealso allowsEmptyModifierFlags

 @seealso requiredModifierFlags
 */
- (BOOL)areModifierFlagsValid:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode;

/*!
 Check whether a given combination is allowed.

 @param  aModifierFlags Proposed modifier flags.

 @param  aKeyCode Code of the pressed key.

 @seealso allowedModifierFlags

 @seealso allowsEmptyModifierFlags

 @seealso requiredModifierFlags
 */
- (BOOL)areModifierFlagsAllowed:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode;

/*!
 Called whenever the control needs to inform a user about misuse, like pressing invalid modifier flags.

 @discussion
 Default implementation uses NSBeep.
 Subclasses can override this method to alter or suppress the sound.
 */
- (void)playAlert;

#pragma mark State

/*!
 @seealso NSControl/enabled
 */
@property (getter=isEnabled) IBInspectable BOOL enabled;

/*!
 @seealso NSControl/refusesFirstResponder
 */
@property IBInspectable BOOL refusesFirstResponder;

/*!
 @seealso NSControl/tag
 */
@property IBInspectable NSInteger tag;

/*!
 Whether recording is currently in progress.
 */
@property (readonly) BOOL isRecording;

/*!
 Whether the control is being highlighted.
 */
@property (getter=isMainButtonHighlighted, readonly) BOOL mainButtonHighlighted;

/*!
 Whether the cancel button is being highlighted.
 */
@property (getter=isCancelButtonHighlighted, readonly) BOOL cancelButtonHighlighted;

/*!
 Whetehr the clear button is being highlighted.
 */
@property (getter=isClearButtonHighlighted, readonly) BOOL clearButtonHighlighted;

/*!
 Called when a user begins recording.
 */
- (BOOL)beginRecording;

/*!
 Called when a user ends recording discarding intermediate value and preserving the current value.
 */
- (void)endRecording;

/*!
 Called when a user ends recording discarding both intermediate and current values.
 */
- (void)clearAndEndRecording;

/*!
 Called when a user ends recording accepting new value.
 */
- (void)endRecordingWithObjectValue:(nullable SRShortcut *)aShortcut;

#pragma mark Value

/*!
 The value of the receiver.

 @discussion
 If the very first non-nil value is an instance of NSDictionary the control will
 enter compatibility mode where objectValue and NSValueBinding accessors will
 accept and return instances of NSDictionary.

 @seealso SRShortcutKey
 */
@property (nullable, copy) SRShortcut *objectValue;

/*!
 Dictionary representation of the shortcut.
 */
@property (nullable, copy) NSDictionary<SRShortcutKey, id> *dictionaryValue;

/*!
 A helper method to propagate view-driven changes back to model.

 @discussion
 This method makes it easier to propagate changes from a view
 back to the model without overriding -bind:toObject:withKeyPath:options:

 @seealso http://tomdalling.com/blog/cocoa/implementing-your-own-cocoa-bindings/
 */
- (void)propagateValue:(nullable id)aValue forBinding:(NSString *)aBinding;

#pragma mark Drawing

/*!
 Current style that determines drawing and layout.

 @seealso SRRecorderControlStyling
 */
@property (null_resettable, copy) id<NSObject, SRRecorderControlStyling> style;

/*!
 Shape of the control for the focus ring.
 */
@property (readonly) NSBezierPath *focusRingShape;

/*!
 Returns label to be displayed by the receiver.
 */
@property (readonly) NSString *drawingLabel __attribute__((annotate("returns_localized_nsstring")));

/*!
 Attirbutes for the drawingLabel.
 */
@property (nullable, readonly) NSDictionary<NSAttributedStringKey, id> *drawingLabelAttributes;

/*!
 Called to make default style for the control.
 */
- (SRRecorderControlStyle *)makeDefaultStyle;

/*!
 Draw background of the control into the current graphics context.
 */
- (void)drawBackground:(NSRect)aDirtyRect;

/*!
 Draw interior of the control into the current graphics context.
 */
- (void)drawInterior:(NSRect)aDirtyRect;

/*!
 Draw label into the current graphics context.

 @seealso drawingLabel

 @seealso drawingLabelAttributes
 */
- (void)drawLabel:(NSRect)aDirtyRect;

/*!
 Draw the cancel button into the current graphics context.
 */
- (void)drawCancelButton:(NSRect)aDirtyRect;

/*!
 Draw the clear button into the current graphics context.
 */
- (void)drawClearButton:(NSRect)aDirtyRect;

/*!
 Called when control's state changes in a way that may affect layout constraints.

 @see style
 */
- (void)updateActiveConstraints;

/*!
 Schedules performSelector to notify style that view's appearance did change.

 @discussion
 Repeated invocation within the iteration of the run loop are coalesced.
 */
- (void)scheduleControlViewAppearanceDidChange:(nullable id)aReason;

@end


@interface SRRecorderControl (Deprecated)

@property (readonly, getter=isCancelButtonHighlighted) BOOL isSnapBackButtonHighlighted __attribute__((deprecated("", "isCancelButtonHighlighted")));

@end


NS_SWIFT_NAME(RecorderControlDelegate)
@protocol SRRecorderControlDelegate <NSObject, NSControlTextEditingDelegate>

@optional

/*!
 Ask the delegate if recording should begin.

 @param aControl The control where recording is about to begin.

 @return YES if recording can being; otherwise, NO.
 */
- (BOOL)recorderControlShouldBeginRecording:(SRRecorderControl *)aControl;

/*!
 Notify the delegate that recording began.

 @param aControl The control where recording began.
*/
- (void)recorderControlDidBeginRecording:(SRRecorderControl *)aControl;

/*!
 Give the delegate the opportunity to bypass rules specified by allowed and required modifier flags.

 @param aControl The shortcut recorder for which editing ended.

 @param aModifierFlags Proposed modifier flags.

 @param aKeyCode Code of the pressed key.

 @return YES if the control should ignore the rules; otherwise, NO.

 @discussion
 Normally, you wouldn't allow a user to record a shourcut without modifier flags set: disallow 'a', but allow cmd-'a'.
 However, some keys are designed to be key shortcuts by itself, e.g. functional keys.
 By implementing this method the delegate can allow these special keys to be set without modifier flags
 even when the control is configured to disallow empty modifier flags.

 @seealso allowedModifierFlags

 @seealso allowsEmptyModifierFlags

 @seealso requiredModifierFlags
 */
- (BOOL)recorderControl:(SRRecorderControl *)aControl shouldUnconditionallyAllowModifierFlags:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode;

/*!
 Ask the delegate if the shortcut can be set.

 @param aControl The control where shortcut was recorded.

 @param  aShortcut The shortcut that was recorded.

 @return YES if the shortcut can be recoded; otherwise, NO.

 @seealso SRShortcutValidator
 */
- (BOOL)recorderControl:(SRRecorderControl *)aControl canRecordShortcut:(SRShortcut *)aShortcut;

/*!
 Notify the delegate that recording ended.

 @param aControl The control where recording ended.
 */
- (void)recorderControlDidEndRecording:(SRRecorderControl *)aControl;

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder canRecordShortcut:(NSDictionary *)aShortcut __attribute__((deprecated("", "recorderControl:canRecordShortcut:")));

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder shouldUnconditionallyAllowModifierFlags:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode __attribute__((deprecated("", "recorderControl:shouldUnconditionallyAllowModifierFlags:forKeyCode:")));

- (BOOL)shortcutRecorderShouldBeginRecording:(SRRecorderControl *)aRecorder __attribute__((deprecated("", "recorderControlShouldBeginRecording:")));

- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder __attribute__((deprecated("", "recorderControlDidEndRecording:")));

@end

NS_ASSUME_NONNULL_END
