#import "SRKeyCombo.h"

static NSString *const SRKeyComboKeyCodeKey = @"keyCode";
static NSString *const SRKeyComboModifierFlagsKey = @"modifierFlags";

@implementation SRKeyCombo

#pragma mark Initialization

- (instancetype) initWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers
{
    self = [super init];
    _keyCode = keyCode;
    _modifiers = modifiers;
    return self;
}

+ (instancetype) keyComboWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers
{
    return [[self alloc] initWithKeyCode:keyCode modifiers:modifiers];
}

+ (instancetype) keyComboWithEvent: (NSEvent*) event
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

- (NSString*) description
{
    NSString *readableString = SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(_modifiers, _keyCode);
    return [NSString stringWithFormat:@"<%@ %p: %@>", [self class], self, readableString];
}

#pragma mark Dictionary Representation

- (NSDictionary*) dictionaryRepresentation
{
    return @{
        SRKeyComboKeyCodeKey : @(_keyCode),
        SRKeyComboModifierFlagsKey : @(_modifiers)
    };
}

// We’re intentionally paranoid here because the dictionary is expected to come from user defaults.
+ (instancetype) keyComboWithDictionaryRepresentation: (NSDictionary*) dictionary
{
    // The dictionary itself might be of other type than NSDictionary.
    if (![dictionary respondsToSelector:@selector(objectForKey:)]) {
        return nil;
    }

    id wrappedKeyCode = dictionary[SRKeyComboKeyCodeKey];
    id wrappedModifiers = dictionary[SRKeyComboModifierFlagsKey];

    // Bail out early if any of the required components are missing.
    if (!dictionary || !wrappedKeyCode || !wrappedModifiers) {
        return nil;
    }

    // Bail out if the wrapped key code looks fishy.
    if (![wrappedKeyCode respondsToSelector:@selector(unsignedIntegerValue)]) {
        return nil;
    }

    // Bail out if the wrapped modifiers field looks fishy.
    if (![wrappedModifiers respondsToSelector:@selector(unsignedIntegerValue)]) {
        return nil;
    }

    return [self keyComboWithKeyCode:[wrappedKeyCode unsignedIntegerValue] modifiers:[wrappedModifiers unsignedIntegerValue]];
}

#pragma mark NSCopying

- (id) copyWithZone: (NSZone*) zone
{
    return [[[self class] allocWithZone:zone] initWithKeyCode:_keyCode modifiers:_modifiers];
}

#pragma mark NSCoding

- (void) encodeWithCoder: (NSCoder*) encoder
{
    [encoder encodeInteger:_keyCode forKey:SRKeyComboKeyCodeKey];
    [encoder encodeInteger:_modifiers forKey:SRKeyComboModifierFlagsKey];
}

- (id) initWithCoder: (NSCoder*) decoder
{
    self = [super init];
    _keyCode = [decoder decodeIntegerForKey:SRKeyComboKeyCodeKey];
    _modifiers = [decoder decodeIntegerForKey:SRKeyComboModifierFlagsKey];
    return self;
}

@end