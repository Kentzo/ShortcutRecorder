//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest

import ShortcutRecorder


class SRCommonTests: XCTestCase {
    func testCocoaModifierFlagsMask() {
        let allFlags = NSEvent.ModifierFlags.init(rawValue: UInt.max)
        let cocoaFlags = allFlags.intersection(CocoaModifierFlagsMask)
        let expectedFlags: NSEvent.ModifierFlags = [.command, .control, .option, .shift, .function]
        XCTAssertEqual(cocoaFlags, expectedFlags)
    }

    func testCarbonModifierFlagsMask() {
        let allFlags = UInt32.max
        let carbonFlags = allFlags & CarbonModifierFlagsMask
        let expectedFlags = UInt32(cmdKey | controlKey | optionKey | shiftKey)
        XCTAssertEqual(carbonFlags, expectedFlags)
    }

    func testKeyCodeGlyphAndString() {
        func compare(glyph: KeyCodeGlyph, string: KeyCodeString, expected: String) {
            XCTContext.runActivity(named: expected) { (_) in
                XCTAssertEqual(String(format: "%C", glyph.rawValue), string.rawValue)
                XCTAssertEqual(string.rawValue, expected)
            }
        }

        compare(glyph: .tabRight, string: .tabRight, expected: "⇥")
        compare(glyph: .tabLeft, string: .tabLeft, expected: "⇤")
        compare(glyph: .return, string: .return, expected: "⌅")
        compare(glyph: .returnR2L, string: .returnR2L, expected: "↩")
        compare(glyph: .deleteLeft, string: .deleteLeft, expected: "⌫")
        compare(glyph: .deleteRight, string: .deleteRight, expected: "⌦")
        compare(glyph: .padClear, string: .padClear, expected: "⌧")
        compare(glyph: .leftArrow, string: .leftArrow, expected: "←")
        compare(glyph: .rightArrow, string: .rightArrow, expected: "→")
        compare(glyph: .upArrow, string: .upArrow, expected: "↑")
        compare(glyph: .downArrow, string: .downArrow, expected: "↓")
        compare(glyph: .pageDown, string: .pageDown, expected: "⇟")
        compare(glyph: .pageUp, string: .pageUp, expected: "⇞")
        compare(glyph: .northwestArrow, string: .northwestArrow, expected: "↖")
        compare(glyph: .southeastArrow, string: .southeastArrow, expected: "↘")
        compare(glyph: .escape, string: .escape, expected: "⎋")
        compare(glyph: .space, string: .space, expected: " ")
    }

    func testModifierFlagGlyphAndString() {
        func compare(glyph: ModifierFlagGlyph, string: ModifierFlagString, expected: String) {
            XCTContext.runActivity(named: expected) { (_) in
                XCTAssertEqual(String(format: "%C", glyph.rawValue), string.rawValue)
                XCTAssertEqual(string.rawValue, expected)
            }
        }

        compare(glyph: .command, string: .command, expected: "⌘")
        compare(glyph: .option, string: .option, expected: "⌥")
        compare(glyph: .shift, string: .shift, expected: "⇧")
        compare(glyph: .control, string: .control, expected: "⌃")
    }

    func testCarbonToCocoaFlags() {
        let carbonFlags = UInt32(cmdKey | controlKey | optionKey | shiftKey)
        let cocoaFlags: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        XCTAssertEqual(carbonToCocoaFlags(carbonFlags), cocoaFlags)
    }

    func testCocoaToCarbonFlags() {
        let carbonFlags = UInt32(cmdKey | controlKey | optionKey | shiftKey)
        let cocoaFlags: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        XCTAssertEqual(cocoaToCarbonFlags(cocoaFlags), carbonFlags)
    }
}
