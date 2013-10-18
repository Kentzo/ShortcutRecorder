//
//  PTHotKey+ShortcutRecorder.h
//  ShortcutRecorder
//
//  Created by Ilya Kulakov on 27.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTHotKey.h"
#import "SRShortcut.h"


@interface PTHotKey (ShortcutRecorder)

+ (PTHotKey *)hotKeyWithIdentifier:(id)anIdentifier
                          shortcut:(SRShortcut *)shortcut
                            target:(id)aTarget
                            action:(SEL)anAction;

+ (PTHotKey *)hotKeyWithIdentifier:(id)anIdentifier
                          shortcut:(SRShortcut *)shortcut
                            target:(id)aTarget
                            action:(SEL)anAction
                        keyUpAction:(SEL)aKeyUpAction;

@end
