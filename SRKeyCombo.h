#import "SRCommon.h"

@interface SRKeyCombo : NSObject <NSCoding>

@property(assign, readonly) NSUInteger keyCode;
@property(assign, readonly) NSUInteger modifiers;

- (id) initWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers;
+ (id) keyComboWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers;
+ (id) keyComboWithEvent: (NSEvent*) event;

@end
