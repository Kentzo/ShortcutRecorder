#import "SRShortcut.h"
#import "SRKeyCodeTransformer.h"

static NSString *const SRShortcutKeyCodeKey = @"keyCode";
static NSString *const SRShortcutModifierFlagsKey = @"modifierFlags";

@implementation SRShortcut

#pragma mark Initialization

- (instancetype) initWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers
{
    self = [super init];
    _keyCode = keyCode;
    _modifiers = modifiers & SRCocoaModifierFlagsMask;
    return self;
}

+ (instancetype) shortcutWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers
{
    return [[self alloc] initWithKeyCode:keyCode modifiers:modifiers];
}

+ (instancetype) shortcutWithEvent: (NSEvent*) event
{
    return [self shortcutWithKeyCode:[event keyCode] modifiers:[event modifierFlags] & SRCocoaModifierFlagsMask];
}

#pragma mark Rendering

- (NSString*) renderedModifiers
{
    return [NSString stringWithFormat:@"%@%@%@%@",
        (_modifiers & NSCommandKeyMask ? SRLoc(@"Command-") : @""),
        (_modifiers & NSAlternateKeyMask ? SRLoc(@"Option-") : @""),
        (_modifiers & NSControlKeyMask ? SRLoc(@"Control-") : @""),
        (_modifiers & NSShiftKeyMask ? SRLoc(@"Shift-") : @"")];
}

- (NSString*) readableString
{
    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedPlainTransformer];
    return [NSString stringWithFormat:@"%@%@", [self renderedModifiers], [t transformedValue:@(_keyCode)]];
}


- (NSString*) readableASCIIString
{
    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedPlainASCIITransformer];
    return [NSString stringWithFormat:@"%@%@", [self renderedModifiers], [t transformedValue:@(_keyCode)]];
}

#pragma mark NSObject

- (BOOL) isEqual: (id) object
{
    return ([object class] == [self class])
        && ([(SRShortcut*) object keyCode] == [self keyCode])
        && ([(SRShortcut*) object modifiers] == [self modifiers]);
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@ %p: %@>", [self class], self, [self readableASCIIString]];
}

- (NSUInteger) hash
{
    return _keyCode + _modifiers;
}

#pragma mark Dictionary Representation

- (NSDictionary*) dictionaryRepresentation
{
    return @{
        SRShortcutKeyCodeKey : @(_keyCode),
        SRShortcutModifierFlagsKey : @(_modifiers)
    };
}

// We’re intentionally paranoid here because the dictionary is expected to come from user defaults.
+ (instancetype) shortcutWithDictionaryRepresentation: (NSDictionary*) dictionary
{
    // The dictionary itself might be of other type than NSDictionary.
    if (![dictionary respondsToSelector:@selector(objectForKey:)]) {
        return nil;
    }

    id wrappedKeyCode = dictionary[SRShortcutKeyCodeKey];
    id wrappedModifiers = dictionary[SRShortcutModifierFlagsKey];

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

    return [self shortcutWithKeyCode:[wrappedKeyCode unsignedIntegerValue] modifiers:[wrappedModifiers unsignedIntegerValue]];
}

#pragma mark NSCopying

- (id) copyWithZone: (NSZone*) zone
{
    return [[[self class] allocWithZone:zone] initWithKeyCode:_keyCode modifiers:_modifiers];
}

#pragma mark NSCoding

- (void) encodeWithCoder: (NSCoder*) encoder
{
    [encoder encodeInteger:_keyCode forKey:SRShortcutKeyCodeKey];
    [encoder encodeInteger:_modifiers forKey:SRShortcutModifierFlagsKey];
}

- (id) initWithCoder: (NSCoder*) decoder
{
    self = [super init];
    _keyCode = [decoder decodeIntegerForKey:SRShortcutKeyCodeKey];
    _modifiers = [decoder decodeIntegerForKey:SRShortcutModifierFlagsKey];
    return self;
}

@end