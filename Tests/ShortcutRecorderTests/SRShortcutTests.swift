//
//  Copyright 2018 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest
import ShortcutRecorder


class SRShortcutTests: XCTestCase {
    /*!
        Raw values of the constants must not be changed for the sake of compatibility.
    */
    func testShortcutKeyEnum() {
        XCTAssertEqual(ShortcutKey.keyCode.rawValue, "keyCode")
        XCTAssertEqual(ShortcutKey.modifierFlags.rawValue, "modifierFlags")
        XCTAssertEqual(ShortcutKey.characters.rawValue, "characters")
        XCTAssertEqual(ShortcutKey.charactersIgnoringModifiers.rawValue, "charactersIgnoringModifiers")
    }

    func testInitialization() {
        let s = Shortcut.default
        XCTAssertEqual(s.keyCode, KeyCode.ansiA)
        XCTAssertEqual(s.modifierFlags, [.option, .command])
        XCTAssertEqual(s.characters, "å")
        XCTAssertEqual(s.charactersIgnoringModifiers, "a")
    }

    func testInitializationWithEvent() {
        let e = NSEvent.keyEvent(with: .keyUp,
                                 location: .zero,
                                 modifierFlags: .option,
                                 timestamp: 0.0,
                                 windowNumber: 0,
                                 context: nil,
                                 characters: "å",
                                 charactersIgnoringModifiers: "a",
                                 isARepeat: false,
                                 keyCode: 0)
        let s = ShortcutRecorder.Shortcut(event: e!)!
        XCTAssertEqual(s.keyCode, KeyCode.ansiA)
        XCTAssertEqual(s.modifierFlags, .option)
        XCTAssertEqual(s.characters, "å")
        XCTAssertEqual(s.charactersIgnoringModifiers, "a")
    }

    func testSubscription() {
        let s = Shortcut.default
        XCTAssertEqual(s[.keyCode] as! UInt16, 0)
        XCTAssertEqual(NSEvent.ModifierFlags(rawValue: s[.modifierFlags] as! UInt), [.option, .command])
        XCTAssertEqual(s[.characters] as! String, "å")
        XCTAssertEqual(s[.charactersIgnoringModifiers] as! String, "a")
    }

    func testKVC() {
        let s = Shortcut.default
        XCTAssertEqual(s.value(forKey: ShortcutKey.keyCode.rawValue) as! UInt16, 0)
        XCTAssertEqual(NSEvent.ModifierFlags(rawValue: s.value(forKey: ShortcutKey.modifierFlags.rawValue) as! UInt), [.option, .command])
        XCTAssertEqual(s.value(forKey: ShortcutKey.characters.rawValue) as! String, "å")
        XCTAssertEqual(s.value(forKey: ShortcutKey.charactersIgnoringModifiers.rawValue) as! String, "a")
    }

    func testDictionaryInitialization() {
        let s1 = Shortcut(dictionary: [ShortcutKey.keyCode: 0])!
        XCTAssertEqual(s1.keyCode, KeyCode.ansiA)
        XCTAssertEqual(s1.modifierFlags, [])
        XCTAssertEqual(s1.characters, "a")
        XCTAssertEqual(s1.charactersIgnoringModifiers, "a")

        let s2 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue])!
        XCTAssertEqual(s2.keyCode, KeyCode.ansiA)
        XCTAssertEqual(s2.modifierFlags, NSEvent.ModifierFlags.option)
        XCTAssertEqual(s2.characters, "å")
        XCTAssertEqual(s2.charactersIgnoringModifiers, "a")

        let s3 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                       ShortcutKey.characters: NSNull(), ShortcutKey.charactersIgnoringModifiers: NSNull()])!
        XCTAssertEqual(s3.keyCode, KeyCode.ansiA)
        XCTAssertEqual(s3.modifierFlags, NSEvent.ModifierFlags.option)
        XCTAssertEqual(s3.characters, "å")
        XCTAssertEqual(s3.charactersIgnoringModifiers, "a")

        let s4 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                       ShortcutKey.characters: "å", ShortcutKey.charactersIgnoringModifiers: "a"])!
        XCTAssertEqual(s4.keyCode, KeyCode.ansiA)
        XCTAssertEqual(s4.modifierFlags, NSEvent.ModifierFlags.option)
        XCTAssertEqual(s4.characters, "å")
        XCTAssertEqual(s4.charactersIgnoringModifiers, "a")
    }

    func testDictionaryRepresentation() {
        let s1 = Shortcut(dictionary: [ShortcutKey.keyCode: 0])!
        XCTAssertEqual(s1.dictionaryRepresentation as NSDictionary, [ShortcutKey.keyCode: 0,
                                                                     ShortcutKey.modifierFlags: 0,
                                                                     ShortcutKey.characters: "a",
                                                                     ShortcutKey.charactersIgnoringModifiers: "a"])

        let s2 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue])!
        XCTAssertEqual(s2.dictionaryRepresentation as NSDictionary, [ShortcutKey.keyCode: 0,
                                                                     ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                                                     ShortcutKey.characters: "å",
                                                                     ShortcutKey.charactersIgnoringModifiers: "a"])

        let s3 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                       ShortcutKey.characters: "å", ShortcutKey.charactersIgnoringModifiers: "a"])!
        XCTAssertEqual(s3.dictionaryRepresentation as NSDictionary, [ShortcutKey.keyCode: 0,
                                                                     ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                                                     ShortcutKey.characters: "å",
                                                                     ShortcutKey.charactersIgnoringModifiers: "a"])
    }

    func testEquality() {
        let s = Shortcut.default
        let modifierFlags: NSEvent.ModifierFlags = [.option, .command]

        XCTAssertEqual(s, s)
        XCTAssertEqual(s, Shortcut.default)
        XCTAssertNotEqual(s, Shortcut(code: KeyCode.ansiA, modifierFlags: .command, characters: nil, charactersIgnoringModifiers: nil));
        XCTAssertTrue(s.isEqual(dictionary: [ShortcutKey.keyCode: 0,
                                             ShortcutKey.modifierFlags: modifierFlags.rawValue,
                                             ShortcutKey.characters: "å",
                                             ShortcutKey.charactersIgnoringModifiers: "a"]))
        XCTAssertFalse(s.isEqual(dictionary: [ShortcutKey.modifierFlags: modifierFlags.rawValue,
                                              ShortcutKey.characters: "å",
                                              ShortcutKey.charactersIgnoringModifiers: "a"]))
    }

    func testSimpleSubclassEquality() {
        class SimpleSubclass: Shortcut {}

        let s1 = Shortcut.default
        let s2 = SimpleSubclass.default as! SimpleSubclass

        XCTAssertEqual(s1, s2)
        XCTAssertEqual(s2, s1)
    }

    func testExtendedSubclassEquality() {
        class ExtendedSubclass: Shortcut {
            var myProperty: Int = 0

            override func isEqual(to aShortcut: Shortcut) -> Bool {
                guard let aShortcut = aShortcut as? ExtendedSubclass else { return false }
                return super.isEqual(to: aShortcut) && self.myProperty == aShortcut.myProperty
            }
        }

        class SimpleOfExtendedSubclass: ExtendedSubclass {}

        class ExtendedOfSimpleOfExtendedSubclass: SimpleOfExtendedSubclass {
            var anotherProperty: Int = 0

            override func isEqual(to aShortcut: Shortcut) -> Bool {
                guard let aShortcut = aShortcut as? ExtendedOfSimpleOfExtendedSubclass else { return false }
                return super.isEqual(to: aShortcut) && self.anotherProperty == aShortcut.anotherProperty
            }
        }

        func AssertEqual(_ a: Shortcut, _ b: Shortcut) {
            XCTAssertEqual(a, b)
            XCTAssertEqual(b, a)
        }

        func AssertNotEqual(_ a: Shortcut, _ b: Shortcut) {
            XCTAssertNotEqual(a, b)
            XCTAssertNotEqual(b, a)
        }

        let s1 = Shortcut.default

        let e1 = ExtendedSubclass.default as! ExtendedSubclass
        let e2 = ExtendedSubclass.default as! ExtendedSubclass
        let e3 = ExtendedSubclass.default as! ExtendedSubclass
        e3.myProperty = 1

        XCTContext.runActivity(named: ExtendedSubclass.className()) { _ in
            AssertNotEqual(s1, e1)
            AssertNotEqual(s1, e2)
            AssertEqual(e1, e2)
            AssertNotEqual(e2, e3)
        }

        let se1 = SimpleOfExtendedSubclass.default as! SimpleOfExtendedSubclass
        let se2 = SimpleOfExtendedSubclass.default as! SimpleOfExtendedSubclass
        let se3 = SimpleOfExtendedSubclass.default as! SimpleOfExtendedSubclass
        se3.myProperty = e3.myProperty + 1

        XCTContext.runActivity(named: SimpleOfExtendedSubclass.className()) { _ in
            AssertNotEqual(se1, s1)
            AssertEqual(se1, e1)
            AssertNotEqual(se1, e3)
            AssertEqual(se1, se2)
            AssertNotEqual(se1, se3)
        }

        let ese1 = ExtendedOfSimpleOfExtendedSubclass.default as! ExtendedOfSimpleOfExtendedSubclass
        let ese2 = ExtendedOfSimpleOfExtendedSubclass.default as! ExtendedOfSimpleOfExtendedSubclass
        let ese3 = ExtendedOfSimpleOfExtendedSubclass.default as! ExtendedOfSimpleOfExtendedSubclass
        ese3.anotherProperty = se3.myProperty + 1

        XCTContext.runActivity(named: SimpleOfExtendedSubclass.className()) { _ in
            AssertNotEqual(ese1, s1)
            AssertNotEqual(ese1, e1)
            AssertNotEqual(ese1, se1)
            AssertEqual(ese1, ese2)
            AssertNotEqual(ese1, ese3)
        }
    }

    func testSiblingSubclassEquality() {
        class ASubclass: Shortcut {}
        class BSubclass: Shortcut {}

        let a = ASubclass.default
        let b = BSubclass.default

        XCTAssertEqual(a, b);
        XCTAssertEqual(b, a);
    }

    func testEncoding() {
        let encoded = try! NSKeyedArchiver.archivedData(withRootObject: Shortcut.default, requiringSecureCoding: true)
        let s = try! NSKeyedUnarchiver.unarchivedObject(ofClass: Shortcut.self, from: encoded)
        XCTAssertEqual(s, Shortcut.default)
    }

    func testCopying() {
        let s = Shortcut.default
        let c = s.copy() as! Shortcut
        XCTAssertEqual(s, c)
    }

    func testKeyEquivalentComparison() {
        typealias KeyEquivalent = (key: String, flags: NSEvent.ModifierFlags)

        func AssertEqual(_ shortcut: Shortcut, _ keyEquivalents: [KeyEquivalent], _ transformer: SymbolicKeyCodeTransformer? = nil) {
            for ke in keyEquivalents {
                if let transformer = transformer {
                    XCTAssertTrue(shortcut.isEqual(keyEquivalent: ke.key, modifierFlags: ke.flags, transformer: transformer),
                                  "\(shortcut) != \(ke.flags.symbolic)\(ke.key) in \((transformer.inputSource as! TISInputSource).identifier)")
                }
                else {
                    XCTAssertTrue(shortcut.isEqual(keyEquivalent: ke.key, modifierFlags: ke.flags),
                                  "\(shortcut) != \(ke.flags.symbolic)\(ke.key) in current")
                }
            }
        }

        func AssertNotEqual(_ shortcut: Shortcut, _ keyEquivalents: [KeyEquivalent], _ transformer: SymbolicKeyCodeTransformer? = nil) {
            for ke in keyEquivalents {
                if let transformer = transformer {
                    XCTAssertFalse(shortcut.isEqual(keyEquivalent: ke.key, modifierFlags: ke.flags, transformer: transformer),
                                   "\(shortcut) == \(ke.flags.symbolic)\(ke.key) in \((transformer.inputSource as! TISInputSource).identifier)")
                }
                else {
                    XCTAssertFalse(shortcut.isEqual(keyEquivalent: ke.key, modifierFlags: ke.flags),
                                   "\(shortcut) == \(ke.flags.symbolic)\(ke.key) in current")
                }
            }
        }

        let us_input = TISInputSource.withIdentifier("com.apple.keylayout.US")!
        let us_transformer = SymbolicKeyCodeTransformer(inputSource: us_input)

        let ru_input = TISInputSource.withIdentifier("com.apple.keylayout.Russian")!
        let ru_transformer = SymbolicKeyCodeTransformer(inputSource: ru_input)

        let a = Shortcut(keyEquivalent: "A")!
        let shift_a = Shortcut(keyEquivalent: "⇧A")!
        let opt_a = Shortcut(keyEquivalent: "⌥A")!
        let opt_shift_a = Shortcut(keyEquivalent: "⇧⌥A")!

        /*
         Note that transformer-less comparisons are done _only_ for ASCII equivalents.
         All other equivalents are input-source dependent.
         */

        let a_ke: [KeyEquivalent] = [
            ("a", [])
        ]

        AssertEqual(a, a_ke)
        AssertEqual(a, a_ke, us_transformer)
        AssertNotEqual(a, a_ke, ru_transformer)

        AssertNotEqual(shift_a, a_ke)
        AssertNotEqual(shift_a, a_ke, us_transformer)
        AssertNotEqual(shift_a, a_ke, ru_transformer)

        AssertNotEqual(opt_a, a_ke)
        AssertNotEqual(opt_a, a_ke, us_transformer)
        AssertNotEqual(opt_a, a_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, a_ke)
        AssertNotEqual(opt_shift_a, a_ke, us_transformer)
        AssertNotEqual(opt_shift_a, a_ke, ru_transformer)

        let A_ke: [KeyEquivalent] = [
            ("a", [.shift]),
            ("A", []),
            ("A", [.shift])
        ]

        AssertNotEqual(a, A_ke)
        AssertNotEqual(a, A_ke, us_transformer)
        AssertNotEqual(a, A_ke, ru_transformer)

        AssertEqual(shift_a, A_ke)
        AssertEqual(shift_a, A_ke, us_transformer)
        AssertNotEqual(shift_a, A_ke, ru_transformer)

        AssertNotEqual(opt_a, A_ke)
        AssertNotEqual(opt_a, A_ke, us_transformer)
        AssertNotEqual(opt_a, A_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, A_ke)
        AssertNotEqual(opt_shift_a, A_ke, us_transformer)
        AssertNotEqual(opt_shift_a, A_ke, ru_transformer)

        let å_ke: [KeyEquivalent] = [
            ("a", [.option]),
            ("å", []),
            ("å", [.option])
        ]

        AssertNotEqual(a, å_ke, us_transformer)
        AssertNotEqual(a, å_ke, ru_transformer)

        AssertNotEqual(shift_a, å_ke, us_transformer)
        AssertNotEqual(shift_a, å_ke, ru_transformer)

        AssertEqual(opt_a, å_ke, us_transformer)
        AssertNotEqual(opt_a, å_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, å_ke, us_transformer)
        AssertNotEqual(opt_shift_a, å_ke, ru_transformer)

        let Å_ke: [KeyEquivalent] = [
            ("a", [.option, .shift]),
            ("A", [.option]),
            ("A", [.option, .shift]),
            ("å", [.shift]),
            ("å", [.option, .shift]),
            ("Å", []),
            ("Å", [.option]),
            ("Å", [.shift]),
            ("Å", [.option, .shift])
        ]

        AssertNotEqual(a, Å_ke, us_transformer)
        AssertNotEqual(a, Å_ke, ru_transformer)

        AssertNotEqual(shift_a, Å_ke, us_transformer)
        AssertNotEqual(shift_a, Å_ke, ru_transformer)

        AssertNotEqual(opt_a, Å_ke, us_transformer)
        AssertNotEqual(opt_a, Å_ke, ru_transformer)

        AssertEqual(opt_shift_a, Å_ke, us_transformer)
        AssertNotEqual(opt_shift_a, Å_ke, ru_transformer)

        let ф_ke: [KeyEquivalent] = [
            ("ф", [])
        ]

        AssertNotEqual(a, ф_ke, us_transformer)
        AssertEqual(a, ф_ke, ru_transformer)

        AssertNotEqual(shift_a, ф_ke, us_transformer)
        AssertNotEqual(shift_a, ф_ke, ru_transformer)

        AssertNotEqual(opt_a, ф_ke, us_transformer)
        AssertNotEqual(opt_a, ф_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, ф_ke, us_transformer)
        AssertNotEqual(opt_shift_a, ф_ke, ru_transformer)

        let Ф_ke: [KeyEquivalent] = [
            ("ф", [.shift]),
            ("Ф", []),
            ("Ф", [.shift])
        ]

        AssertNotEqual(a, Ф_ke, us_transformer)
        AssertNotEqual(a, Ф_ke, ru_transformer)

        AssertNotEqual(shift_a, Ф_ke, us_transformer)
        AssertEqual(shift_a, Ф_ke, ru_transformer)

        AssertNotEqual(opt_a, Ф_ke, us_transformer)
        AssertNotEqual(opt_a, Ф_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, Ф_ke, us_transformer)
        AssertNotEqual(opt_shift_a, Ф_ke, ru_transformer)

        let opt_ф_ke: [KeyEquivalent] = [
            ("ф", [.option])
        ]

        AssertNotEqual(a, opt_ф_ke, us_transformer)
        AssertNotEqual(a, opt_ф_ke, ru_transformer)

        AssertNotEqual(shift_a, opt_ф_ke, us_transformer)
        AssertNotEqual(shift_a, opt_ф_ke, ru_transformer)

        AssertNotEqual(opt_a, opt_ф_ke, us_transformer)
        AssertEqual(opt_a, opt_ф_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, opt_ф_ke, us_transformer)
        AssertNotEqual(opt_shift_a, opt_ф_ke, ru_transformer)

        let ƒ_ke: [KeyEquivalent] = [
            ("ƒ", []),
            ("ƒ", [.option]),
        ]

        AssertNotEqual(a, ƒ_ke, us_transformer)
        AssertNotEqual(a, ƒ_ke, ru_transformer)

        AssertNotEqual(shift_a, ƒ_ke, us_transformer)
        AssertNotEqual(shift_a, ƒ_ke, ru_transformer)

        AssertNotEqual(opt_a, ƒ_ke, us_transformer)
        AssertEqual(opt_a, ƒ_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, ƒ_ke, us_transformer)
        AssertEqual(opt_shift_a, ƒ_ke, ru_transformer)

        let shift_ƒ_ke: [KeyEquivalent] = [
            ("ф", [.option, .shift]),
            ("Ф", [.option]),
            ("Ф", [.option, .shift]),
            ("ƒ", [.shift]),
            ("ƒ", [.option, .shift]),
        ]

        AssertNotEqual(a, shift_ƒ_ke, us_transformer)
        AssertNotEqual(a, shift_ƒ_ke, ru_transformer)

        AssertNotEqual(shift_a, shift_ƒ_ke, us_transformer)
        AssertNotEqual(shift_a, shift_ƒ_ke, ru_transformer)

        AssertNotEqual(opt_a, shift_ƒ_ke, us_transformer)
        AssertNotEqual(opt_a, shift_ƒ_ke, ru_transformer)

        AssertNotEqual(opt_shift_a, shift_ƒ_ke, us_transformer)
        AssertEqual(opt_shift_a, shift_ƒ_ke, ru_transformer)

        let ctrl_tab = Shortcut(code: KeyCode.tab, modifierFlags: [.control], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertTrue(ctrl_tab.isEqual(keyEquivalent: "\u{0009}", modifierFlags: [.control]))
        XCTAssertTrue(ctrl_tab.isEqual(keyEquivalent: "\u{0019}", modifierFlags: [.control]))

        let ctrl_del = Shortcut(code: KeyCode.delete, modifierFlags: [.control], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertTrue(ctrl_del.isEqual(keyEquivalent: "\u{0008}", modifierFlags: [.control]));
        XCTAssertFalse(ctrl_del.isEqual(keyEquivalent: "\u{007f}", modifierFlags: [.control]));

        let ctrl_fdel = Shortcut(code: KeyCode.forwardDelete, modifierFlags: [.control], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertFalse(ctrl_fdel.isEqual(keyEquivalent: "\u{0008}", modifierFlags: [.control]));
        XCTAssertTrue(ctrl_fdel.isEqual(keyEquivalent: "\u{007f}", modifierFlags: [.control]));
    }

    func testInitializationWithKeyEquivalent() {
        let shift_cmd_a = Shortcut(code: KeyCode.ansiA, modifierFlags: [.shift, .command], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(Shortcut(keyEquivalent: "⇧⌘A"), shift_cmd_a)

        let ctrl_esc = Shortcut(code: KeyCode.escape, modifierFlags: [.control], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(Shortcut(keyEquivalent: "⌃Escape"), ctrl_esc)
    }

    func testInitializationWithFlagsChangedEvent() {
        let shift_cmd_down_event = NSEvent.keyEvent(with: .flagsChanged,
                                              location: NSPoint(),
                                              modifierFlags: [.shift, .command],
                                              timestamp: 0,
                                              windowNumber: 0,
                                              context: nil,
                                              characters: "",
                                              charactersIgnoringModifiers: "",
                                              isARepeat: false,
                                              keyCode: UInt16(kVK_Command))!
        let shift_cmd_up_event = NSEvent.keyEvent(with: .flagsChanged,
                                            location: NSPoint(),
                                            modifierFlags: [.shift],
                                            timestamp: 0,
                                            windowNumber: 0,
                                            context: nil,
                                            characters: "",
                                            charactersIgnoringModifiers: "",
                                            isARepeat: false,
                                            keyCode: UInt16(kVK_Command))!
        let shift_cmd = Shortcut(keyEquivalent: "⇧⌘")
        XCTAssertEqual(shift_cmd, Shortcut(event: shift_cmd_down_event))
        XCTAssertEqual(shift_cmd, Shortcut(event: shift_cmd_up_event))
    }
    
    func testSplittingKeyEquiv() {
        
        struct splitTestCase {
            var keyEquiv: String
            var expectedModifiers: String
            var expectedKeyCode: String
        }

        
        let testCases = [ splitTestCase(keyEquiv: "⇧⌘K", expectedModifiers: "⇧⌘", expectedKeyCode: "K"),
                          splitTestCase(keyEquiv: "⇧⌘", expectedModifiers: "⇧⌘", expectedKeyCode: ""),
                          splitTestCase(keyEquiv: "fn⇧⌘K", expectedModifiers: "fn⇧⌘", expectedKeyCode: "K"),
                          splitTestCase(keyEquiv: "fn", expectedModifiers: "fn", expectedKeyCode: ""),
                          splitTestCase(keyEquiv: "fnf", expectedModifiers: "fn", expectedKeyCode: "f"),
                          splitTestCase(keyEquiv: "fnF", expectedModifiers: "fn", expectedKeyCode: "F"),
                          splitTestCase(keyEquiv: "⇧⌘KS", expectedModifiers: "⇧⌘", expectedKeyCode: "KS"),
        ]
        
        for testCase in testCases {
            
            let both = splitKeycodeEquivalent(testCase.keyEquiv)
            
            let splits = both.components(separatedBy: SRSplitKeycodeSeparator)
            
            XCTAssertEqual(splits.count, 2)
            
            XCTAssertEqual(splits[0], testCase.expectedModifiers)
            XCTAssertEqual(splits[1], testCase.expectedKeyCode)
            
            print(both)
            
        }
        
    }
}
