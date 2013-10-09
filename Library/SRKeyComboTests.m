#import "SRKeyCombo.h"

@interface SRKeyComboTests : XCTestCase
@end

@implementation SRKeyComboTests

- (void) testEquality
{
    SRKeyCombo *comboA = [SRKeyCombo keyComboWithKeyCode:1 modifiers:NSCommandKeyMask];
    SRKeyCombo *comboB = [SRKeyCombo keyComboWithKeyCode:1 modifiers:NSCommandKeyMask];
    SRKeyCombo *comboC = [SRKeyCombo keyComboWithKeyCode:1 modifiers:NSAlternateKeyMask];
    SRKeyCombo *comboD = [SRKeyCombo keyComboWithKeyCode:2 modifiers:NSAlternateKeyMask];

    XCTAssertEqualObjects(comboA, comboA, @"Shortcut equals to itself.");
    XCTAssertEqualObjects(comboA, comboB, @"Shortcuts equal if key codes and masks equal.");
    XCTAssertNotEqualObjects(comboA, comboC, @"Shortcuts not equal if masks differ.");
    XCTAssertNotEqualObjects(comboC, comboD, @"Shortcuts not equal if key codes differ.");
    XCTAssertNotEqualObjects(comboC, nil, @"Shortcuts not equal if the second one is nil.");
}

- (void) testCoding
{
    SRKeyCombo *combo = [SRKeyCombo keyComboWithKeyCode:1 modifiers:NSCommandKeyMask];
    NSData *freezedCombo = [NSKeyedArchiver archivedDataWithRootObject:combo];
    XCTAssertNotNil(freezedCombo, @"Archive shortcut into NSData.");
    SRKeyCombo *thawed = [NSKeyedUnarchiver unarchiveObjectWithData:freezedCombo];
    XCTAssertEqual([thawed keyCode], (NSUInteger)1, @"Archive and unarchive key code.");
    XCTAssertEqual([thawed modifiers], (NSUInteger)NSCommandKeyMask, @"Archive and unarchive modifiers.");
}

- (void) testCopying
{
    SRKeyCombo *combo = [SRKeyCombo keyComboWithKeyCode:1 modifiers:NSCommandKeyMask];
    SRKeyCombo *copy = [combo copy];
    XCTAssertEqualObjects(combo, copy, @"Copied shortcut equal to the source one.");
}

- (void) testDictionaryRepresentation
{
    SRKeyCombo *combo = [SRKeyCombo keyComboWithKeyCode:1 modifiers:NSCommandKeyMask];
    NSDictionary *dictionary = [combo dictionaryRepresentation];

    // Test dictionary encoding
    XCTAssertEqualObjects(dictionary[@"keyCode"], @1, @"Store key code in dictionary representation.");
    XCTAssertEqualObjects(dictionary[@"modifierFlags"], @(NSCommandKeyMask), @"Store modifier flags in dictionary representation.");

    // Test basic dictionary decoding
    SRKeyCombo *thawed = [SRKeyCombo keyComboWithDictionaryRepresentation:dictionary];
    XCTAssertEqualObjects(thawed, combo, @"Recreate a shortcut from a dictionary representation.");

    // Test invalid value decoding. Since the dictionary may come from user
    // defaults, we have to take care to handle invalid input gracefully.
    XCTAssertNil([SRKeyCombo keyComboWithDictionaryRepresentation:nil],
        @"Decoding a shortcut from a nil dictionary returns nil.");
    XCTAssertNil([SRKeyCombo keyComboWithDictionaryRepresentation:(id)@"foo"],
        @"Decoding a shortcut from a invalid-type dictionary returns nil.");
    XCTAssertNil([SRKeyCombo keyComboWithDictionaryRepresentation:@{}],
        @"Decoding a shortcut from an empty dictionary returns nil.");
    XCTAssertNil([SRKeyCombo keyComboWithDictionaryRepresentation:@{@"keyCode":@"foo"}],
        @"Decoding a shortcut from a wrong-typed dictionary returns nil.");
    XCTAssertNil([SRKeyCombo keyComboWithDictionaryRepresentation:@{@"keyCode":@1}],
        @"Decoding a shortcut from an incomplete dictionary returns nil.");
    XCTAssertNil([SRKeyCombo keyComboWithDictionaryRepresentation:@{@"modifierFlags":@1}],
        @"Decoding a shortcut from an incomplete dictionary returns nil.");
}

@end
