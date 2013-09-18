#import "SRKeyCombo.h"

@implementation SRKeyCombo

#pragma mark Initialization

- (id) initWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers
{
    self = [super init];
    _keyCode = keyCode;
    _modifiers = modifiers;
    return self;
}

+ (id) keyComboWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers
{
    return [[self alloc] initWithKeyCode:keyCode modifiers:modifiers];
}

+ (id) keyComboWithEvent: (NSEvent*) event
{
    return [self keyComboWithKeyCode:[event keyCode] modifiers:[event modifierFlags] & SRCocoaModifierFlagsMask];
}

#pragma mark NSObject

- (BOOL) isEqual: (id) object
{
    return ([object class] == [self class])
        && ([(SRKeyCombo*) object keyCode] == [self keyCode])
        && ([(SRKeyCombo*) object modifiers] == [self modifiers]);
}

#pragma mark NSCoding

static NSString *const SRKeyComboKeyCodeKey = @"keyCode";
static NSString *const SRKeyComboModifiersKey = @"modifiers";

- (void) encodeWithCoder: (NSCoder*) encoder
{
    [encoder encodeInteger:_keyCode forKey:SRKeyComboKeyCodeKey];
    [encoder encodeInteger:_modifiers forKey:SRKeyComboModifiersKey];
}

- (id) initWithCoder: (NSCoder*) decoder
{
    self = [super init];
    _keyCode = [decoder decodeIntegerForKey:SRKeyComboKeyCodeKey];
    _modifiers = [decoder decodeIntegerForKey:SRKeyComboModifiersKey];
    return self;
}

@end
