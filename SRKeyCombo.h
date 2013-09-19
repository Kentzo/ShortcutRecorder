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

- (instancetype) initWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers;
+ (instancetype) keyComboWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers;

/*!
    @brief Creates a new key combo from an NSEvent object.
    @discussion This is just a convenience initializer that reads the key code
    and modifiers from an NSEvent.
*/
+ (instancetype) keyComboWithEvent: (NSEvent*) event;

@end
