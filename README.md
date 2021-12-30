[![CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-important.svg)](http://creativecommons.org/licenses/by/4.0/)
![macOS 10.11](https://img.shields.io/badge/macOS-10.11%2B-informational.svg)
![Mac App Store Approved](https://img.shields.io/badge/Mac%20App%20Store-Approved-success.svg)

[![CocoaPods Compatible](https://img.shields.io/badge/CocoaPods-Compatible%201.8+-success.svg)](https://cocoapods.org/pods/ShortcutRecorder)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-success.svg)](https://github.com/Carthage/Carthage)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-success.svg)](https://swiftpackageindex.com/Kentzo/ShortcutRecorder)

[![Coverage](https://codecov.io/gh/Kentzo/ShortcutRecorder/branch/master/graph/badge.svg)](https://codecov.io/gh/Kentzo/ShortcutRecorder)
[![Build Status](https://travis-ci.org/Kentzo/ShortcutRecorder.svg?branch=master)](https://travis-ci.org/Kentzo/ShortcutRecorder)

# ShortcutRecorder

![Showcase](https://user-images.githubusercontent.com/88809/67132003-e4b8b780-f1bb-11e9-984d-2c88fc8c2286.gif)

The best control to record shortcuts on macOS

- Objective-C framework developed with Swift in mind
- Easily stylable
- Translated into 22 languages
- Supports macOS Accessibility
- Thoroughly documented and tested
- Global and Local shortcuts for both key up and key down actions
- Mac App Store approved
- End-to-end Interface Builder integration

## What is inside

The framework comes with:
- `SRRecorderControl` to render and capture user input
- `SRRecorderControlStyle` for custom styling
- `SRShortcut` that represents a shortcut model
- `SRGlobalShortcutMonitor` to turn the shortcut into an action by registering a global hot key
- `SRAXGlobalShortcutMonitor` to handle any kind of keyboard event via Accessibility
- `SRLocalShortcutMonitor` for manual handling in the responder chain and `NSEvent` monitors
- `SRShortcutController` for smooth Cocoa Bindings and seamless Interface Builder integration
- `SRShortcutValidator` to check validity of the shortcut against Cocoa key equivalents and global hot keys
- `NSValueTransformer` and `NSFormatter` subclasses for custom alterations

In Swift:

```swift
import ShortcutRecorder

let defaults = NSUserDefaultsController.shared
let keyPath = "values.shortcut"
let options = [NSBindingOption.valueTransformerName: .keyedUnarchiveFromDataTransformerName]

let beepAction = ShortcutAction(keyPath: keyPath, of: defaults) { _ in
    NSSound.beep()
    return true
}
GlobalShortcutMonitor.shared.addAction(beepAction, forKeyEvent: .down)

let recorder = RecorderControl()
recorder.bind(.value, to: defaults, withKeyPath: keyPath, options: options)

recorder.objectValue = Shortcut(keyEquivalent: "⇧⌘A")
```

In Objective-C:

```objective-c
#import <ShortcutRecorder/ShortcutRecorder.h>

NSUserDefaultsController *defaults = NSUserDefaultsController.sharedUserDefaultsController;
NSString *keyPath = @"values.shortcut";
NSDictionary *options = @{NSValueTransformerNameBindingOption: NSKeyedUnarchiveFromDataTransformerName};

SRShortcutAction *beepAction = [SRShortcutAction shortcutActionWithKeyPath:keyPath
                                                                  ofObject:defaults
                                                             actionHandler:^BOOL(SRShortcutAction *anAction) {
    NSBeep();
    return YES;
}];
[[SRGlobalShortcutMonitor sharedMonitor] addAction:beepAction forKeyEvent:SRKeyEventTypeDown];

SRRecorderControl *recorder = [SRRecorderControl new];
[recorder bind:NSValueBinding toObject:defaults withKeyPath:keyPath options:options];

recorder.objectValue = [SRShortcut shortcutWithKeyEquivalent:@"⇧⌘A"];
```

## Integration

The framework supports [module maps](https://clang.llvm.org/docs/Modules.html), explicit linking is not required: simply `import ShortcutRecorder` /  `#import <ShortcutRecorder/ShortcutRecorder.h>`

### Swift Package Manager

    .package(url: "git://github.com/Kentzo/ShortcutRecorder.git", from: "3.3.0")

### CocoaPods

    pod 'ShortcutRecorder', '~> 3.3.0'

### Carthage

    github "Kentzo/ShortcutRecorder" ~> 3.3.0

Prebuilt frameworks are available via GitHub releases.

### Git Submodule

    git submodule add git://github.com/Kentzo/ShortcutRecorder.git

Then drag'n'drop into Xcode workspace of your project.

## Next Steps

- The Documentation playground covers all parts of the framework (see in Xcode)
- The Inspector app is useful during development of custom styles
- Read about [Styling](https://github.com/Kentzo/ShortcutRecorder/wiki/Styling) and special notes regarding [Cocoa's Key Equivalents](https://github.com/Kentzo/ShortcutRecorder/wiki/Cocoa-Key-Equivalents).

## Coding Style

Please use (four) spaces for indentation. It's not that all contributors prefer spaces over tabs or vice versa. Most of the code in the project used spaces at one point and it was easier to convert the occasional tab than all the spaces.

## Questions

Still have questions? [Create an issue](https://github.com/Kentzo/ShortcutRecorder/issues/new).

## Paid Support

Paid support is available for custom alterations, help with integration and general advice regarding development for Apple's platforms.
