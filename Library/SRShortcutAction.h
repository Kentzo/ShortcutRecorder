//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Cocoa/Cocoa.h>

#import <ShortcutRecorder/SRShortcut.h>


/*!
 @header
 A collection of classes to bind shortcuts to actions and monitor these actions in
 event streams.
 */


NS_ASSUME_NONNULL_BEGIN

@class SRShortcutAction;

/*!
 @param anAction The action that invoked the handler.

 @return YES if the action was performed; NO otherwise.
 */
typedef BOOL (^SRShortcutActionHandler)(SRShortcutAction *anAction) NS_SWIFT_NAME(SRShortcutAction.Action);


NS_SWIFT_NAME(ShortcutActionTarget)
@protocol SRShortcutActionTarget;


/*!
 A connection between a shortcut and an action.

 @discussion
 The associated shortcut can be set directly or it can be observed from another object. In the latter case
 whenever new value is observed, the shortcut property is updated in a KVO-complient way.

 The associated action can be a selector or a block.
 A target for the selector can be stored inside the action, but can also be provided directly
 to the -performActionOnTarget: method. This is convenient when the target is not known
 at the time when the action is created.

 The target may adapt the SRShortcutActionTarget protocol instead of implementing a method for each action.
 Additionaly, the NSUserInterfaceValidations protocol can be adapted to determine whether the action should be ignored.

 Both selector and block implementations must return a boolean determining whether the action
 was actually performed. This helps the monitor to find the suitable action when there are multiple
 actions per a shortcut.
 */
NS_SWIFT_NAME(ShortcutAction)
@interface SRShortcutAction : NSObject <NSValidatedUserInterfaceItem, NSUserInterfaceItemIdentification>

/*!
 Instantiate a selector-based action bound to the shortcut.
 */
+ (instancetype)shortcutActionWithShortcut:(SRShortcut *)aShortcut
                                    target:(nullable id)aTarget
                                    action:(nullable SEL)anAction
                                       tag:(NSInteger)aTag;

/*!
 Instantiate a selector-based action bound to the shortcut.
 */
+ (instancetype)shortcutActionWithShortcut:(SRShortcut *)aShortcut
                                    target:(nullable id)aTarget
                                    action:(nullable SEL)anAction
                               actionKeyUp:(nullable SEL)anActionKeyUp
                                       tag:(NSInteger)aTag;

/*!
 Instantiate a block-based action bound to the shortcut.
 */
+ (instancetype)shortcutActionWithShortcut:(SRShortcut *)aShortcut
                             actionHandler:(SRShortcutActionHandler)anActionHandler;

/*!
 Instantiate a block-based action bound to the shortcut that handles the keyDown and keyUp events separately
 */
+ (instancetype)shortcutActionWithShortcut:(SRShortcut *)aShortcut
                             actionHandler:(SRShortcutActionHandler)anActionHandler
                        actionHandlerKeyUp:(SRShortcutActionHandler)anActionHandlerKeyUp;

/*!
 Instantiate a selector-based action bound to the autoupdating shortcut.
 */
+ (instancetype)shortcutActionWithKeyPath:(NSString *)aKeyPath
                                 ofObject:(id)anObject
                                   target:(nullable id)aTarget
                                   action:(nullable SEL)anAction
                                      tag:(NSInteger)aTag;

/*!
 Instantiate a selector-based action bound to the autoupdating shortcut.
 */
+ (instancetype)shortcutActionWithKeyPath:(NSString *)aKeyPath
                                 ofObject:(id)anObject
                                   target:(nullable id)aTarget
                                   action:(nullable SEL)anAction
                              actionKeyUp:(nullable SEL)anActionKeyUp
                                      tag:(NSInteger)aTag;

/*!
 Instantiate a block-based action bound to the autoupdating shortcut.
 */
+ (instancetype)shortcutActionWithKeyPath:(NSString *)aKeyPath
                                 ofObject:(id)anObject
                            actionHandler:(SRShortcutActionHandler)anActionHandler;

/*!
 Instantiate a block-based action bound to the autoupdating shortcut.
 */
+ (instancetype)shortcutActionWithKeyPath:(NSString *)aKeyPath
                                 ofObject:(id)anObject
                            actionHandler:(SRShortcutActionHandler)anActionHandler
                       actionHandlerKeyUp:(SRShortcutActionHandler)anActionHandlerKeyUp;

/*!
 The shortcut associated with the action.

 @note Setting the shortcut resets observation.
 */
@property (nullable, copy) SRShortcut *shortcut;

/*!
 The object being observed for the autoupdating shortcut.
 */
@property (nullable, weak, readonly) id observedObject;

/*!
 The key path being observed for the autoupdating shortcut.
 */
@property (nullable, copy, readonly) NSString *observedKeyPath;

/*!
 The target to receive the associated action-message selector.

 @discussion
 Defaults to NSApplication.sharedApplication

 @note Setting the target resets the action handler.

 @seealso SRShortcutActionTarget
 */
@property (null_resettable, weak) id target;

/*!
 The selector associated with the action.

 @discussion
 May be nil if the target conforms to the SRShortcutActionTarget protocol.
 */
@property (nullable) SEL action;

/*!
 The selector associated with the keyUp action.

 @discussion
 May be nil if the target conforms to the SRShortcutActionTarget protocol.
 */
@property (nullable) SEL actionKeyUp;

/*!
 The handler to execute when the action is performed.

 @note Setting the handler resets the target.
 */
@property (nullable) SRShortcutActionHandler actionHandler;

/*!
 The handler to execute when the action is released.

 @note Setting the handler resets the target.
 */
@property (nullable) SRShortcutActionHandler actionHandlerKeyUp;

/*!
 The tag identifying the receiver.
 */
@property NSInteger tag;

/*!
 Whether the action is enabled.
 */
@property (getter=isEnabled) BOOL enabled;

/*!
 Configure the autoupdating shortcut by observing the given key path of the given object.

 @discussion
 anObservedObject is expected to return one of:
 - SRShortcut
 - A compatible NSDictionary representation
 - NSData of encoded SRShortcut
 - nil / NSNull

 @note To stop observation set the shortcut to nil or any other value.
 */
- (void)setObservedObject:(id)anObservedObject withKeyPath:(NSString *)aKeyPath;

/*!
 Perform the associated action, if any, on the given target, if possible.

 @param aTarget Target to perform the associated action. If nil, defaults to action's target.

 @discussion
 Disabled actions return NO immediately.

 If there is an associated action handler, it is performed and aTarget is ignored.
 Otherwise, the associated action is performed if:
 1. aTarget either implements the action or adopts the SRShortcutActionTarget protocol
 2. aTarget's -validateUserInterfaceItem:, if implemented, returns YES

 @return YES if the action was performed; NO otherwise.
 */
- (BOOL)performActionOnTarget:(nullable id)aTarget;

/*!
Perform the associated actionKeyUp, if any, on the given target, if possible.

@param aTarget Target to perform the associated action. If nil, defaults to action's target.

@discussion
Disabled actions return NO immediately.

If there is an associated action handler, it is performed and aTarget is ignored.
Otherwise, the associated action is performed if:
1. aTarget either implements the action or adopts the SRShortcutActionTarget protocol
2. aTarget's -validateUserInterfaceItem:, if implemented, returns YES

@return YES if the action was performed; NO otherwise.
*/
- (BOOL)performActionKeyUpOnTarget:(nullable id)aTarget;

@end


/*!
 A target of SRShortcutAction may adopt this protocol to receive a message without implementing distinct methods.
 The implementation may use anAction's tag and identifier properties to distinguish senders.

 @seealso NSValidatedUserInterfaceItem
 @seealso NSUserInterfaceItemIdentification
 */
@protocol SRShortcutActionTarget
- (BOOL)performShortcutAction:(SRShortcutAction *)anAction NS_SWIFT_NAME(perform(shortcutAction:));
@optional
- (BOOL)performShortcutActionKeyUp:(SRShortcutAction *)anAction NS_SWIFT_NAME(perform(shortcutActionKeyUp:));
@end


/*!
 Base class for the SRGlobalShortcutMonitor and SRLocalShortcutMonitor.

 @discussion
 Observes shortcuts assigned to actions and automatically rearranges internal storage.

 The monitor supports multiple actions associated with the same shortcut. When that happens,
 the monitor attempts to perform the most recent action that claimed the shortcut first. If it fails,
 it tries the next most recent one and so on until either an action is succesfully performed or the list
 of candidates is exhousted.

 The recency of actions is established first by the order of addition and then by the recency
 of the dynamic shortcut change (both direct and through observation).
 */
NS_SWIFT_NAME(ShortcutMonitor)
@interface SRShortcutMonitor : NSObject

/*!
 All associated shortcut actions in no particular order.
 */
@property (readonly) NSArray<SRShortcutAction *> *shortcutActions;

/*!
 All shortcuts being currently monitored in no particular order.
 */
@property (readonly) NSSet<SRShortcut *> *allShortcuts;

/*!
 Add an action to the monitor.

 @note Adding the same action twice has no effect.
 */
- (void)addShortcutAction:(SRShortcutAction *)anAction;

/*!
 Remove an action from the monitor.
 */
- (void)removeShortcutAction:(SRShortcutAction *)anAction;

/*!
 The most recent action associated with the shortcut.
 */
- (nullable SRShortcutAction *)actionForShortcut:(SRShortcut *)aShortcut;

/*!
 All actions associated with the shortcut.

 @return
 An array of actions currently associated with the shortcut ordered by the time of association
 such as that the last object is the most recently associated. If the shortcut has no associated actions,
 returns an empty array.
 */
- (NSArray<SRShortcutAction *> *)allActionsForShortcut:(SRShortcut *)aShortcut;

/*!
 Called after the shortcut gets its first associated action.
 */
- (void)didAddShortcut:(SRShortcut *)aShortcut;

/*!
 Called after the shortcut loses its last associated action.
 */
- (void)didRemoveShortcut:(SRShortcut *)aShortcut;

@end


@interface SRShortcutMonitor (SRShortcutMonitorConveniences)

/*!
 Create and add new shortcut action with the given parameters.
 */
- (nullable SRShortcutAction *)addAction:(SEL)anAction forKeyEquivalent:(NSString *)aKeyEquivalent tag:(NSInteger)aTag;

@end


/*!
 Handle shortcuts regardless of the currently active application.

 @discussion
 Action that corresponds to the shortcut is performed asyncrhonoysly in the specified dispatch queue.
 */
NS_SWIFT_NAME(GlobalShortcutMonitor)
@interface SRGlobalShortcutMonitor : SRShortcutMonitor

@property (class, readonly) SRGlobalShortcutMonitor *sharedMonitor NS_SWIFT_NAME(shared);

/*!
 Target dispatch queue for the action.

 @discussion:
 Defaults to the main queue.

 The action block is detached and submitted asynchronously to the given queue.

 @seealso DISPATCH_BLOCK_NO_QOS_CLASS
 */
@property dispatch_queue_t dispatchQueue;

/*!
 Enable system-wide shortcut monitoring.

 @discussion
 This method has an underlying counter, i.e. every pause must be matched with a resume.
 The initial state is resumed.
 */
- (void)resume;

/*!
 Disable system-wide shortcut monitoring.

 @discussion
 This method has an underlying counter, i.e. every pause must be matched with a resume.
 The initial state is resumed.
 */
- (void)pause;

/*!
 Perform the action associated with the event, if any.

 @param anEvent A Carbon hot key event.

 @discussion
 If there is more than one action associated with the event, they are performed one by one
 either until one of them returns YES or the iteration is exhausted.
 */
- (OSStatus)handleEvent:(nullable EventRef)anEvent;

@end


/*!
 Handle AppKit's keyboard events.

 @discussion
 The monitor does not intercept any events. Instead they must be passed directly. Override NSView/NSWindow
 or NSViewController/NSWindowController or use NSEvent's monitoring API to pass keyboard events
 via the -handleEvent:withTarget: method.
 */
NS_SWIFT_NAME(LocalShortcutMonitor)
@interface SRLocalShortcutMonitor : SRShortcutMonitor

/*!
 Text navigation and editing shortcuts.

 @seealso NSStandardKeyBindingResponding
 */
@property (class, readonly) SRLocalShortcutMonitor *standardShortcuts;

/*!
 Shortcuts that mimic default main menu for a new Cocoa Applications.
 */
@property (class, readonly) SRLocalShortcutMonitor *mainMenuShortcuts;

/*!
 Shortcuts associated with the clipboard.

 - cut:
 - copy:
 - paste:
 - pasteAsPlainText:
 - redo:
 - undo:
 */
@property (class, readonly) SRLocalShortcutMonitor *clipboardShortcuts;

/*!
 Shortcuts associated with window management.

 - performClose:
 - performMiniaturize:
 - toggleFullScreen:
 */
@property (class, readonly) SRLocalShortcutMonitor *windowShortcuts;

/*!
 Key bindings associated with document management.

 - print:
 - runPageLayout:
 - revertDocumentToSaved:
 - saveDocument:
 - saveDocumentAs:
 - duplicateDocument:
 - openDocument:
 */
@property (class, readonly) SRLocalShortcutMonitor *documentShortcuts;

/*!
 Key bindings associated with application management.

 - hide:
 - hideOtherApplications:
 - terminate:
 */
@property (class, readonly) SRLocalShortcutMonitor *appShortcuts;

/*!
 Perform the action associated with the event, if any.

 @param anEvent An AppKit keyboard event.

 @param aTarget Target to pass to the -[SRShortcutAction performActionOnTarget:] method.

 @discussion
 If there are more than one action associated with the event, they are performed one by one
 either until one of them returns YES or the iteration is exhausted.
 */
- (BOOL)handleEvent:(nullable NSEvent *)anEvent withTarget:(nullable id)aTarget;

/*!
 Update the monitor with system-wide and user-specific Cocoa Text System key bindings.

 @seealso https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/TextDefaultsBindings/TextDefaultsBindings.html
 */
- (void)updateWithCocoaTextKeyBindings;

@end

NS_ASSUME_NONNULL_END
