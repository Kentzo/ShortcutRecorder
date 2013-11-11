#import "SRCommon.h"

@interface SRShortcut : NSObject <NSCoding, NSCopying>

/*!
    @brief The virtual key code for the keyboard key.
    @discussion Hardware independent, same as in NSEvent.
    @see Events.h in the HIToolbox framework for a complete list.
*/
@property(assign, readonly) NSUInteger keyCode;

/*!
    @brief Cocoa keyboard modifier flags.
    @discussion Same as in NSEvent: NSCommandKeyMask, NSAlternateKeyMask, etc.
*/
@property(assign, readonly) NSUInteger modifiers;

/*!
    @brief A string representation of the shortcut with modifier flags replaced
    with their localized readable equivalents (e.g. ⌥ -> Option).
*/
@property(copy, readonly) NSString *readableString;

/*!
    @brief A string representation of the shortcut with modifier flags replaced with their
    localized readable equivalents (e.g. ⌥ -> Option) and ASCII character for key code.
 */
@property(copy, readonly) NSString *readableASCIIString;

/*!
    @brief Returns a dictionary representation of the shortcut.
    @discussion Useful for storing the shortcuts in user defaults.
*/
@property(copy, readonly) NSDictionary *dictionaryRepresentation;

- (instancetype) initWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers;
+ (instancetype) shortcutWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers;
+ (instancetype) shortcutWithDictionaryRepresentation: (NSDictionary*) dictionary;

/*!
    @brief Creates a new shortcut from an NSEvent object.
    @discussion This is just a convenience initializer that reads the key code
    and modifiers from an NSEvent.
*/
+ (instancetype) shortcutWithEvent: (NSEvent*) event;

/*!
    @brief Returns YES if the shortcut matches a given key equivalent with modifiers.
    @discussion This method is useful for comparing shortcuts to key equivalents
    returned by NSButton, NSMenu, and similar controls. (“Is this button assigned
    this shortcut?”)

    An interesting catch is that some key equivalent modifier flags can be set implicitly
    using special Unicode characters, for example the Option-a shortcut should match a key
    equivalent “å” with zero modifiers. However all modifier flags explictly set for the key
    equivalent must be also set in key code flags: a key equivalent “å” with a Control
    modifier matches a Control-Option-a shortcut, but a key equivalent “å” with a Command
    modifier does not match a Control-Option-a shortcut.
*/
- (BOOL) matchesKeyEquivalent: (NSString*) keyEquivalent withModifiers: (NSUInteger) modifiers;

@end