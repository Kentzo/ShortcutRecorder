//
//  IKIBAutoLayoutWindowController.m
//  ShortcutRecorderDemo
//
//  Created by Ilya Kulakov on 18.01.13.
//  Copyright (c) 2013 Ilya Kulakov. All rights reserved.
//

#import "IKIBAutoLayoutWindowController.h"


@implementation IKIBAutoLayoutWindowController

#pragma mark NSObject

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    
    [self.pingShortcutRecorder bind:SRRecorderControlDictionaryValueBinding
                           toObject:defaults
                        withKeyPath:@"values.ping"
                            options:nil];
    [self.pingShortcutRecorder bind:SRRecorderControlDictionaryValueBinding
                           toObject:defaults
                        withKeyPath:@"values.isPingItemEnabled"
                            options:nil];
    [self.pingShortcutRecorder setAllowedModifierFlags:NSShiftKeyMask | NSAlternateKeyMask | NSCommandKeyMask
                                 requiredModifierFlags:0
                              allowsEmptyModifierFlags:NO];
    [self.globalPingShortcutRecorder bind:SRRecorderControlDictionaryValueBinding
                                 toObject:defaults
                              withKeyPath:@"values.globalPing"
                                  options:nil];
    [self.pingItemShortcutRecorder bind:SRRecorderControlDictionaryValueBinding
                               toObject:defaults
                            withKeyPath:@"values.pingItem"
                                options:nil];
}

@end
