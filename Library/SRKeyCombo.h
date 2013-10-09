#import "SRCommon.h"

@interface SRKeyCombo : NSObject <NSCoding, NSCopying>

/*!
    @brief The virtual key code for the keyboard key.
    @discussion Hardware independent, same as in NSEvent.
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
+ (instancetype) keyComboWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers;
+ (instancetype) keyComboWithDictionaryRepresentation: (NSDictionary*) dictionary;

/*!
    @brief Creates a new key combo from an NSEvent object.
    @discussion This is just a convenience initializer that reads the key code
    and modifiers from an NSEvent.
*/
+ (instancetype) keyComboWithEvent: (NSEvent*) event;

@end