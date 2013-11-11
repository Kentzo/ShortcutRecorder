#import "SRShortcut.h"
#import "SRKeyCodeTransformer.h"

static NSString *const SRShortcutKeyCodeKey = @"keyCode";
static NSString *const SRShortcutModifierFlagsKey = @"modifierFlags";

@implementation SRShortcut

#pragma mark Initialization

- (instancetype) initWithKeyCode: (NSUInteger) keyCode modifiers: (NSUInteger) modifiers
{
    self = [super init];
    if (self) {
        _keyCode = keyCode;
        _modifiers = modifiers & SRCocoaModifierFlagsMask;
    }
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

- (NSString*) readableModifiers
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
    return [NSString stringWithFormat:@"%@%@", [self readableModifiers], [t transformedValue:@(_keyCode)]];
}


- (NSString*) readableASCIIString
{
    SRKeyCodeTransformer *t = [SRKeyCodeTransformer sharedPlainASCIITransformer];
    return [NSString stringWithFormat:@"%@%@", [self readableModifiers], [t transformedValue:@(_keyCode)]];
}

#pragma mark NSObject

- (BOOL) isEqual: (SRShortcut*) object
{
    if (object == self) {
        return YES;
    }

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    return ([object keyCode] == [self keyCode]) && ([object modifiers] == [self modifiers]);
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], [self readableASCIIString]];
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

#pragma mark Key Equivalents

- (BOOL) matchesKeyEquivalent: (NSString*) keyEquivalent withModifiers: (NSUInteger) keyEquivalentModifiers transformer: (SRKeyCodeTransformer*) transformer
{
    if (!keyEquivalent) {
        return NO;
    }

    keyEquivalentModifiers &= SRCocoaModifierFlagsMask;

    // Simple case: the modifiers match, we just have to compare the key equivalent.
    if (keyEquivalentModifiers == _modifiers) {
        NSString *keyCodeRepresentation = [transformer transformedValue:@(_keyCode)
            withImplicitModifierFlags:nil explicitModifierFlags:@(_modifiers)];
        return [keyCodeRepresentation isEqual:keyEquivalent];
    }

    // Harder case: the key equivalent modifiers are zero or a superset of our modifiers.
    else if (!keyEquivalentModifiers || (_modifiers & keyEquivalentModifiers) == keyEquivalentModifiers)
    {
        NSString *keyCodeRepresentation = [transformer transformedValue:@(_keyCode)
            withImplicitModifierFlags:nil explicitModifierFlags:@(_modifiers)];
        if ([keyCodeRepresentation isEqual:keyEquivalent]) {
            // If the key representation matches, there can be no implicit modifiers.
            // And since the explicit modifiers don’t match and there are no implicit ones,
            // the shortcut doesn’t match the given key equivalent because of modifiers.
            return NO;
        } else {
            // The key representation doesn’t match, so it’s possible that there are
            // some implicit modifiers hidden in the key equivalent (like the Option
            // modifier in “å”). We’ll extract the possible implicit modifiers, add
            // them to our explicit modifiers and compare the key equivalents again
            // (like Option-“a” instead of “å”).
            NSUInteger possibleImplicitFlags = _modifiers & ~keyEquivalentModifiers;
            keyCodeRepresentation = [transformer transformedValue:@(_keyCode)
                withImplicitModifierFlags:@(possibleImplicitFlags)
                explicitModifierFlags:@(keyEquivalentModifiers)];
            return [keyCodeRepresentation isEqual:keyEquivalent];
        }
    }

    // Modifiers don’t match at all.
    return NO;
}

- (BOOL) matchesKeyEquivalent: (NSString*) keyEquivalent withModifiers: (NSUInteger) keyEquivalentModifiers
{
    return [self matchesKeyEquivalent:keyEquivalent withModifiers:keyEquivalentModifiers transformer:[SRKeyCodeTransformer sharedASCIITransformer]]
        || [self matchesKeyEquivalent:keyEquivalent withModifiers:keyEquivalentModifiers transformer:[SRKeyCodeTransformer sharedTransformer]];
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