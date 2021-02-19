//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest

import ShortcutRecorder

class SRModifierFlagsTransformerTests: XCTestCase {
    func testSymbolicTransformerIsReversible() {
        let flags: NSEvent.ModifierFlags = [.control, .option, .shift, .command, .function]
        let transformer = SymbolicModifierFlagsTransformer.shared
        let string = transformer.transformedValue(flags.rawValue as NSNumber)!
        let restoredFlags = NSEvent.ModifierFlags(rawValue: transformer.reverseTransformedValue(string) as! UInt)
        XCTAssertEqual(flags, restoredFlags)

        XCTAssertNil(transformer.reverseTransformedValue(string + string))
    }
}
