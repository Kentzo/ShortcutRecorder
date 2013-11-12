#import "SRShortcut.h"

@interface SRShortcutTests : XCTestCase
@end

@implementation SRShortcutTests

- (void) testEquality
{
    SRShortcut *shortcutA = [SRShortcut shortcutWithKeyCode:1 modifiers:NSCommandKeyMask];
    SRShortcut *shortcutB = [SRShortcut shortcutWithKeyCode:1 modifiers:NSCommandKeyMask];
    SRShortcut *shortcutC = [SRShortcut shortcutWithKeyCode:1 modifiers:NSAlternateKeyMask];
    SRShortcut *shortcutD = [SRShortcut shortcutWithKeyCode:2 modifiers:NSAlternateKeyMask];

    XCTAssertEqualObjects(shortcutA, shortcutA, @"Shortcut equals to itself.");
    XCTAssertEqualObjects(shortcutA, shortcutB, @"Shortcuts equal if key codes and masks equal.");
    XCTAssertNotEqualObjects(shortcutA, shortcutC, @"Shortcuts not equal if masks differ.");
    XCTAssertNotEqualObjects(shortcutC, shortcutD, @"Shortcuts not equal if key codes differ.");
    XCTAssertNotEqualObjects(shortcutC, nil, @"Shortcuts not equal if the second one is nil.");
}

- (void) testCoding
{
    SRShortcut *shortcut = [SRShortcut shortcutWithKeyCode:1 modifiers:NSCommandKeyMask];
    NSData *freezedShortcut = [NSKeyedArchiver archivedDataWithRootObject:shortcut];
    XCTAssertNotNil(freezedShortcut, @"Archive shortcut into NSData.");
    SRShortcut *thawed = [NSKeyedUnarchiver unarchiveObjectWithData:freezedShortcut];
    XCTAssertEqual([thawed keyCode], (NSUInteger)1, @"Archive and unarchive key code.");
    XCTAssertEqual([thawed modifiers], (NSUInteger)NSCommandKeyMask, @"Archive and unarchive modifiers.");
}

- (void) testCopying
{
    SRShortcut *shortcut = [SRShortcut shortcutWithKeyCode:1 modifiers:NSCommandKeyMask];
    SRShortcut *copy = [shortcut copy];
    XCTAssertEqualObjects(shortcut, copy, @"Copied shortcut equal to the source one.");
}

- (void) testDictionaryRepresentation
{
    SRShortcut *shortcut = [SRShortcut shortcutWithKeyCode:1 modifiers:NSCommandKeyMask];
    NSDictionary *dictionary = [shortcut dictionaryRepresentation];

    // Test dictionary encoding
    XCTAssertEqualObjects(dictionary[@"keyCode"], @1, @"Store key code in dictionary representation.");
    XCTAssertEqualObjects(dictionary[@"modifierFlags"], @(NSCommandKeyMask), @"Store modifier flags in dictionary representation.");

    // Test basic dictionary decoding
    SRShortcut *thawed = [SRShortcut shortcutWithDictionaryRepresentation:dictionary];
    XCTAssertEqualObjects(thawed, shortcut, @"Recreate a shortcut from a dictionary representation.");

    // Test invalid value decoding. Since the dictionary may come from user
    // defaults, we have to take care to handle invalid input gracefully.
    XCTAssertNil([SRShortcut shortcutWithDictionaryRepresentation:nil],
        @"Decoding a shortcut from a nil dictionary returns nil.");
    XCTAssertNil([SRShortcut shortcutWithDictionaryRepresentation:(id)@"foo"],
        @"Decoding a shortcut from a invalid-type dictionary returns nil.");
    XCTAssertNil([SRShortcut shortcutWithDictionaryRepresentation:@{}],
        @"Decoding a shortcut from an empty dictionary returns nil.");
    XCTAssertNil([SRShortcut shortcutWithDictionaryRepresentation:@{@"keyCode":@"foo"}],
        @"Decoding a shortcut from a wrong-typed dictionary returns nil.");
    XCTAssertNil([SRShortcut shortcutWithDictionaryRepresentation:@{@"keyCode":@1}],
        @"Decoding a shortcut from an incomplete dictionary returns nil.");
    XCTAssertNil([SRShortcut shortcutWithDictionaryRepresentation:@{@"modifierFlags":@1}],
        @"Decoding a shortcut from an incomplete dictionary returns nil.");
}

- (void) testKeyEquivalentMatching
{
    SRShortcut *shortcut = [SRShortcut shortcutWithKeyCode:kVK_ANSI_A modifiers:NSAlternateKeyMask];
    XCTAssertFalse([shortcut matchesKeyEquivalent:nil withModifiers:0],
        @"No shortcut matches a nil key equivalent.");
    XCTAssertFalse([shortcut matchesKeyEquivalent:@"" withModifiers:0],
        @"No shortcut matches an empty key equivalent.");
    XCTAssertTrue([shortcut matchesKeyEquivalent:@"a" withModifiers:NSAlternateKeyMask],
        @"Shortcut matches a key equivalent with matching modifiers.");
}

// The implicit modifier matching breaks under some keyboard layouts,
// see https://github.com/Kentzo/ShortcutRecorder/issues/30
- (void) testKeyEquivalentMatchingWithImplicitModifiers
{
    SRShortcut *shortcut = [SRShortcut shortcutWithKeyCode:kVK_ANSI_A modifiers:NSAlternateKeyMask];
    XCTAssertTrue([shortcut matchesKeyEquivalent:@"å" withModifiers:0],
        @"Shortcut matches a Unicode key equivalent with matching implicit modifiers.");
    XCTAssertFalse([shortcut matchesKeyEquivalent:@"å" withModifiers:NSCommandKeyMask],
        @"Shortcut does not match a Unicode key equivalent with matching implicit modifiers, but different explicit modifier.");
}

@end
