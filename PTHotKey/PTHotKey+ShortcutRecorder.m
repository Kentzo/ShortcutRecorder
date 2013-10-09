//
//  PTHotKey+ShortcutRecorder.m
//  ShortcutRecorder
//
//  Created by Ilya Kulakov on 27.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "PTHotKey+ShortcutRecorder.h"
#import "SRRecorderControl.h"


@implementation PTHotKey (ShortcutRecorder)

+ (PTHotKey *)hotKeyWithIdentifier:(id)anIdentifier
                          keyCombo:(SRKeyCombo *)aKeyCombo
                            target:(id)aTarget
                            action:(SEL)anAction
{
    NSUInteger carbonModifiers = SRCocoaToCarbonFlags([aKeyCombo modifiers]);
    PTKeyCombo *newKeyCombo = [[[PTKeyCombo alloc] initWithKeyCode:aKeyCombo.keyCode modifiers:carbonModifiers] autorelease];
    PTHotKey *newHotKey = [[[PTHotKey alloc] initWithIdentifier:anIdentifier keyCombo:newKeyCombo] autorelease];
    [newHotKey setTarget:aTarget];
    [newHotKey setAction:anAction];
    return newHotKey;
}

+ (PTHotKey *)hotKeyWithIdentifier:(id)anIdentifier
                          keyCombo:(SRKeyCombo *)aKeyCombo
                            target:(id)aTarget
                            action:(SEL)anAction
                       keyUpAction:(SEL)aKeyUpAction
{				
    PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:anIdentifier
                                                keyCombo:aKeyCombo
                                                  target:aTarget
                                                  action:anAction];
    [newHotKey setKeyUpAction:aKeyUpAction];
    return newHotKey;
}

@end
