//
//  Copyright 2006 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <limits.h>
#import <objc/runtime.h>
#import <os/trace.h>
#import <os/activity.h>

#import "SRRecorderControl.h"
#import "SRShortcutAction.h"
#import "SRKeyCodeTransformer.h"
#import "SRModifierFlagsTransformer.h"


typedef NS_ENUM(NSUInteger, _SRRecorderControlButtonTag)
{
    _SRRecorderControlInvalidButtonTag = -1,
    _SRRecorderControlCancelButtonTag = 0,
    _SRRecorderControlClearButtonTag = 1,
    _SRRecorderControlMainButtonTag = 2
};


static NSInteger _SRStyleUserInterfaceLayoutDirectionObservingContext;
static NSInteger _SRStyleAppearanceObservingContext;


#define _SRIfRespondsGet(obj, sel, default) [obj respondsToSelector:@selector(sel)] ? [obj sel] : (default)
#define _SRIfRespondsGetProp(obj, sel, prop, default) [obj respondsToSelector:@selector(sel)] ? [[obj sel] prop] : (default)


@implementation SRRecorderControl
{
    SRRecorderControlStyle *_style;
    NSInvocation *_notifyStyle;

    NSTrackingArea *_mainButtonTrackingArea;
    NSTrackingArea *_cancelButtonTrackingArea;
    NSTrackingArea *_clearButtonTrackingArea;

    _SRRecorderControlButtonTag _mouseTrackingButtonTag;
    NSToolTipTag _cancelButtonToolTipTag;
    NSToolTipTag _clearButtonToolTipTag;

    SRShortcut *_objectValue;

    // +NSEvent.modifierFlags may change across run loop calls
    // Extra care is needed to ensure that all methods will see the same flags.
    NSEventModifierFlags _currentlyDrawnRecordingModifierFlags;
    NSEventModifierFlags _accessibilityRecordingModifierFlags;

    BOOL _isLazilyInitializingStyle;
}

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];

    if (self)
    {
        [self initInternalState];
    }

    return self;
}

- (void)initInternalState
{
    self.enabled = YES;
    _allowsEmptyModifierFlags = NO;
    _drawsASCIIEquivalentOfShortcut = YES;
    _allowsEscapeToCancelRecording = YES;
    _allowsDeleteToClearShortcutAndEndRecording = YES;
    _allowedModifierFlags = SRCocoaModifierFlagsMask;
    _requiredModifierFlags = 0;
    _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    _cancelButtonToolTipTag = NSIntegerMax;
    _clearButtonToolTipTag = NSIntegerMax;
    _pausesGlobalShortcutMonitorWhileRecording = YES;

    _notifyStyle = [NSInvocation invocationWithMethodSignature:[SRRecorderControlStyle instanceMethodSignatureForSelector:@selector(recorderControlAppearanceDidChange:)]];
    _notifyStyle.selector = @selector(recorderControlAppearanceDidChange:);
    [_notifyStyle retainArguments];

    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self setContentHuggingPriority:NSLayoutPriorityDefaultLow
                     forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentHuggingPriority:NSLayoutPriorityRequired
                     forOrientation:NSLayoutConstraintOrientationVertical];

    [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                   forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentCompressionResistancePriority:NSLayoutPriorityRequired
                                   forOrientation:NSLayoutConstraintOrientationVertical];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_notifyStyle];
}

#pragma mark Properties
@dynamic style;

+ (BOOL)automaticallyNotifiesObserversOfValue
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfObjectValue
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfStringValue
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfAttributedStringValue
{
    return NO;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingDictionaryValue
{
    return [NSSet setWithObject:@"objectValue"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingStringValue
{
    return [NSSet setWithObjects:@"objectValue", @"userInterfaceLayoutDirection", @"stringValueRespectsUserInterfaceLayoutDirection", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingAttributedStringValue
{
    return [NSSet setWithObject:@"stringValue"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingUserInterfaceLayoutDirection
{
    return [NSSet setWithObject:@"style"];
}

- (void)setAllowedModifierFlags:(NSEventModifierFlags)newAllowedModifierFlags
          requiredModifierFlags:(NSEventModifierFlags)newRequiredModifierFlags
       allowsEmptyModifierFlags:(BOOL)newAllowsEmptyModifierFlags
{
    newAllowedModifierFlags &= SRCocoaModifierFlagsMask;
    newRequiredModifierFlags &= SRCocoaModifierFlagsMask;

    if ((newAllowedModifierFlags & newRequiredModifierFlags) != newRequiredModifierFlags)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Required flags (%lu) MUST be allowed (%lu)", newAllowedModifierFlags, newRequiredModifierFlags];
    }

    if (newAllowsEmptyModifierFlags && newRequiredModifierFlags != 0)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Empty modifier flags MUST be disallowed if required modifier flags are not empty."];
    }

    if (newAllowedModifierFlags == _allowedModifierFlags &&
        newRequiredModifierFlags == _requiredModifierFlags &&
        newAllowsEmptyModifierFlags == _allowsEmptyModifierFlags)
    {
        return;
    }

    [self endRecording];

    [self willChangeValueForKey:@"allowedModifierFlags"];
    [self willChangeValueForKey:@"requiredModifierFlags"];
    [self willChangeValueForKey:@"allowsEmptyModifierFlags"];
    _allowedModifierFlags = newAllowedModifierFlags;
    _requiredModifierFlags = newRequiredModifierFlags;
    _allowsEmptyModifierFlags = newAllowsEmptyModifierFlags;
    [self didChangeValueForKey:@"allowedModifierFlags"];
    [self didChangeValueForKey:@"requiredModifierFlags"];
    [self didChangeValueForKey:@"allowsEmptyModifierFlags"];
}

- (SRShortcut *)objectValue
{
    if (_isCompatibilityModeEnabled)
        return (id)_objectValue.dictionaryRepresentation;
    else
        return _objectValue;
}

- (void)setObjectValue:(SRShortcut *)newObjectValue
{
    if (newObjectValue == _objectValue || [newObjectValue isEqual:_objectValue])
        return;

    [self willChangeValueForKey:@"objectValue"];
    // Cocoa KVO and KVC frequently uses NSNull as object substituation of nil.
    // SRRecorderControl expects either nil or valid object value, it's convenient
    // to handle NSNull here and convert it into nil.
    if ((NSNull *)newObjectValue == NSNull.null)
        newObjectValue = nil;
    // Backward compatibility with Shortcut Recorder 2
    else if ([newObjectValue isKindOfClass:NSDictionary.class] && _objectValue == nil)
    {
        NSLog(@"WARNING: Shortcut Recroder 2 compatibility mode enabled. Getters of objectValue and NSValueBinding will return an instance of NSDictionary.");
        _isCompatibilityModeEnabled = YES;
        newObjectValue = [SRShortcut shortcutWithDictionary:(NSDictionary *)newObjectValue];
    }

    _objectValue = [newObjectValue copy];
    [self didChangeValueForKey:@"objectValue"];

    if (_isCompatibilityModeEnabled)
        [self propagateValue:_objectValue.dictionaryRepresentation forBinding:NSValueBinding];
    else
        [self propagateValue:_objectValue forBinding:NSValueBinding];

    if (!self.isRecording)
    {
        NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);
        NSAccessibilityPostNotification(self, NSAccessibilityValueChangedNotification);
        [self setNeedsDisplayInRect:self.style.labelDrawingGuide.frame];
    }
}

- (NSDictionary<SRShortcutKey, id> *)dictionaryValue
{
    return _objectValue.dictionaryRepresentation;
}

- (void)setDictionaryValue:(NSDictionary<SRShortcutKey, id> *)newDictionaryValue
{
    self.objectValue = [SRShortcut shortcutWithDictionary:newDictionaryValue];
}

- (id)value
{
    return self.objectValue;
}

- (void)setValue:(id)newValue
{
    if (NSIsControllerMarker(newValue))
        [NSException raise:NSInternalInconsistencyException format:@"SRRecorderControl's NSValueBinding does not support controller value markers."];

    self.objectValue = newValue;
}

- (SRRecorderControlStyle *)style
{
    if (_style == nil)
    {
        _isLazilyInitializingStyle = YES;
        [self _setStyle:[self makeDefaultStyle]];
        _isLazilyInitializingStyle = NO;
    }

    return _style;
}

- (void)setStyle:(SRRecorderControlStyle *)newStyle
{
    if (newStyle == nil)
        newStyle = [self makeDefaultStyle];
    else if ([newStyle isEqual:_style])
        return;
    else
        newStyle = [newStyle copy];

    [self _setStyle:newStyle];
}

- (void)_setStyle:(SRRecorderControlStyle *)newStyle
{
    [NSObject cancelPreviousPerformRequestsWithTarget:_notifyStyle];

    if ([_style respondsToSelector:@selector(prepareForRemoval)])
        [_style prepareForRemoval];

    if ([_style respondsToSelector:@selector(preferredComponents)])
    {
        [_style removeObserver:self forKeyPath:@"preferredComponents.userInterfaceLayoutDirection" context:&_SRStyleUserInterfaceLayoutDirectionObservingContext];
        [_style removeObserver:self forKeyPath:@"preferredComponents.appearance" context:&_SRStyleAppearanceObservingContext];
    }

    _style = newStyle;

    if ([_style respondsToSelector:@selector(prepareForRecorderControl:)])
        [_style prepareForRecorderControl:self];

    if ([_style respondsToSelector:@selector(preferredComponents)])
    {
        [_style addObserver:self
                 forKeyPath:@"preferredComponents.userInterfaceLayoutDirection"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionPrior
                    context:&_SRStyleUserInterfaceLayoutDirectionObservingContext];
        [_style addObserver:self
                 forKeyPath:@"preferredComponents.appearance"
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:&_SRStyleAppearanceObservingContext];
    }

    if (self.isRecording)
        self.toolTip = _SRIfRespondsGet(self.style, recordingTooltip, SRLoc(@"Type shortcut"));
    else
        self.toolTip = _SRIfRespondsGet(self.style, normalTooltip, SRLoc(@"Click to record shortcut"));
}

- (NSBezierPath *)focusRingShape
{
    NSRect focusRingFrame = _SRIfRespondsGetProp(self.style, backgroundDrawingGuide, frame, self.bounds);

    NSEdgeInsets alignmentInsets = self.alignmentRectInsets;
    NSEdgeInsets focusRingInsets = _SRIfRespondsGet(self.style, focusRingInsets, NSEdgeInsetsZero);
    NSSize cornerRadius = _SRIfRespondsGet(self.style, focusRingCornerRadius, NSZeroSize);

    focusRingFrame.origin.x += alignmentInsets.left + focusRingInsets.left;
    focusRingFrame.origin.y += alignmentInsets.top + focusRingInsets.top;
    focusRingFrame.size.width = fdim(focusRingFrame.size.width,
                                     alignmentInsets.left + alignmentInsets.right + focusRingInsets.left + focusRingInsets.right);
    focusRingFrame.size.height = fdim(focusRingFrame.size.height,
                                      alignmentInsets.top + alignmentInsets.bottom + focusRingInsets.top + focusRingInsets.bottom);

    return [NSBezierPath bezierPathWithRoundedRect:focusRingFrame
                                           xRadius:cornerRadius.width
                                           yRadius:cornerRadius.height];
}

- (BOOL)isMainButtonHighlighted
{
    if (_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream
                                           fromView:nil];
        return [self mouse:locationInView inRect:self.bounds];
    }
    else
        return NO;
}

- (BOOL)isCancelButtonHighlighted
{
    if (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream
                                           fromView:nil];
        NSRect cancelButtonFrame = _SRIfRespondsGetProp(self.style,
                                                      cancelButtonLayoutGuide,
                                                      frame,
                                                      _SRIfRespondsGetProp(self.style,
                                                                         cancelButtonDrawingGuide,
                                                                         frame,
                                                                         NSZeroRect));
        return [self mouse:locationInView inRect:cancelButtonFrame];
    }
    else
        return NO;
}

- (BOOL)isClearButtonHighlighted
{
    if (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag)
    {
        NSPoint locationInView = [self convertPoint:self.window.mouseLocationOutsideOfEventStream
                                           fromView:nil];
        NSRect clearButtonFrame = _SRIfRespondsGetProp(self.style,
                                                     clearButtonLayoutGuide,
                                                     frame,
                                                     _SRIfRespondsGetProp(self.style,
                                                                        clearButtonDrawingGuide,
                                                                        frame,
                                                                        NSZeroRect));
        return [self mouse:locationInView inRect:clearButtonFrame];
    }
    else
        return NO;
}

- (NSString *)drawingLabel
{
    NSString *label = nil;

    if (self.isRecording)
    {
        _currentlyDrawnRecordingModifierFlags = NSEvent.modifierFlags & self.allowedModifierFlags;

        if (_currentlyDrawnRecordingModifierFlags)
        {
            __auto_type layoutDirection = self.stringValueRespectsUserInterfaceLayoutDirection ? self.userInterfaceLayoutDirection : NSUserInterfaceLayoutDirectionLeftToRight;
            label = [SRSymbolicModifierFlagsTransformer.sharedTransformer transformedValue:@(_currentlyDrawnRecordingModifierFlags)
                                                                           layoutDirection:layoutDirection];
        }
        else
            label = self.stringValue;

        if (!label.length)
            label = _SRIfRespondsGet(self.style, noValueRecordingLabel, SRLoc(@"Type shortcut"));
    }
    else
    {
        label = self.stringValue;

        if (!label.length)
            label = _SRIfRespondsGet(self.style, noValueNormalLabel, SRLoc(@"Record Shortcut"));
    }

    return label;
}

- (NSDictionary *)drawingLabelAttributes
{
    if (self.enabled)
    {
        if (self.isRecording)
            return _SRIfRespondsGet(self.style, recordingLabelAttributes, nil);
        else
            return _SRIfRespondsGet(self.style, normalLabelAttributes, nil);
    }
    else
        return _SRIfRespondsGet(self.style, disabledLabelAttributes, nil);
}

#pragma mark Methods

- (SRRecorderControlStyle *)makeDefaultStyle
{
    return [SRRecorderControlStyle new];
}

- (BOOL)beginRecording
{
    __block BOOL result = NO;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __auto_type DelegateShouldBeginRecording = ^{
        if ([self.delegate respondsToSelector:@selector(recorderControlShouldBeginRecording:)])
            return [self.delegate recorderControlShouldBeginRecording:self];
        else if ([self.delegate respondsToSelector:@selector(shortcutRecorderShouldBeginRecording:)])
            return [self.delegate shortcutRecorderShouldBeginRecording:self];
        else
            return YES;
    };
#pragma clang diagnostic pop

    os_activity_initiate("beginRecording", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (!self.enabled)
        {
            result = NO;
            return;
        }

        if (self.isRecording)
        {
            result = YES;
            return;
        }

        BOOL shouldBeginRecording = DelegateShouldBeginRecording();

        if (!shouldBeginRecording)
        {
            [self playAlert];
            result = NO;
            return;
        }

        if (![self.window makeFirstResponder:self])
        {
            [self playAlert];
            result = NO;
            return;
        }

        self.needsDisplay = YES;

        [self willChangeValueForKey:@"isRecording"];
        self->_isRecording = YES;
        [self didChangeValueForKey:@"isRecording"];

        [self updateActiveConstraints];
        [self updateTrackingAreas];
        self.toolTip = _SRIfRespondsGet(self.style, recordingTooltip, SRLoc(@"Type shortcut"));

        if (self.pausesGlobalShortcutMonitorWhileRecording)
            [SRGlobalShortcutMonitor.sharedMonitor pause];

        NSDictionary *bindingInfo = [self infoForBinding:NSValueBinding];
        if (bindingInfo)
        {
            id controller = bindingInfo[NSObservedObjectKey];
            if ([controller respondsToSelector:@selector(objectDidBeginEditing:)])
                [controller objectDidBeginEditing:(id<NSEditor>) self];
        }

        if ([self.delegate respondsToSelector:@selector(recorderControlDidBeginRecording:)])
            [self.delegate recorderControlDidBeginRecording:self];

        NSAccessibilityPostNotificationWithUserInfo(self,
                                                    NSAccessibilityLayoutChangedNotification,
                                                    @{NSAccessibilityUIElementsKey: @[self]});
        NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);

        result = YES;
    });

    return result;
}

- (void)endRecording
{
    if (!self.isRecording)
        return;

    os_activity_initiate("endRecording via cancel", OS_ACTIVITY_FLAG_DEFAULT, ^{
        [self endRecordingWithObjectValue:self->_objectValue];
    });
}

- (void)clearAndEndRecording
{
    if (!self.isRecording)
        return;

    os_activity_initiate("endRecording via clear", OS_ACTIVITY_FLAG_DEFAULT, ^{
        [self endRecordingWithObjectValue:nil];
    });
}

- (void)endRecordingWithObjectValue:(SRShortcut *)anObjectValue
{
    if (!self.isRecording)
        return;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __auto_type DelegateDidEndRecording = ^{
        if ([self.delegate respondsToSelector:@selector(recorderControlDidEndRecording:)])
            [self.delegate recorderControlDidEndRecording:self];
        else if ([self.delegate respondsToSelector:@selector(shortcutRecorderDidEndRecording:)])
            [self.delegate shortcutRecorderDidEndRecording:self];
    };
#pragma clang diagnostic pop

    os_activity_initiate("endRecording explicitly", OS_ACTIVITY_FLAG_IF_NONE_PRESENT, ^{
        [self willChangeValueForKey:@"isRecording"];
        self->_isRecording = NO;
        [self didChangeValueForKey:@"isRecording"];

        self.objectValue = anObjectValue;
        self->_currentlyDrawnRecordingModifierFlags = 0;
        self->_accessibilityRecordingModifierFlags = 0;

        [self updateActiveConstraints];
        [self updateTrackingAreas];
        self.toolTip = _SRIfRespondsGet(self.style, normalTooltip, SRLoc(@"Click to record shortcut"));
        self.needsDisplay = YES;

        if (self.pausesGlobalShortcutMonitorWhileRecording)
            [SRGlobalShortcutMonitor.sharedMonitor resume];

        NSDictionary *bindingInfo = [self infoForBinding:NSValueBinding];
        if (bindingInfo)
        {
            id controller = bindingInfo[NSObservedObjectKey];
            if ([controller respondsToSelector:@selector(objectDidEndEditing:)])
                [controller objectDidEndEditing:(id<NSEditor>)self];
        }

        if (self.window.firstResponder == self && !self.canBecomeKeyView)
            [self.window makeFirstResponder:nil];

        DelegateDidEndRecording();

        [self sendAction:self.action to:self.target];

        NSAccessibilityPostNotificationWithUserInfo(self,
                                                    NSAccessibilityLayoutChangedNotification,
                                                    @{NSAccessibilityUIElementsKey: @[self]});
        NSAccessibilityPostNotification(self, NSAccessibilityTitleChangedNotification);
    });
}

- (void)updateActiveConstraints
{
    [NSLayoutConstraint activateConstraints:self.style.alwaysConstraints];

    if (self.isRecording && _objectValue)
    {
        [NSLayoutConstraint deactivateConstraints:self.style.displayingConstraints];
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithNoValueConstraints];
        [NSLayoutConstraint activateConstraints:self.style.recordingWithValueConstraints];
    }
    else if (self.isRecording)
    {
        [NSLayoutConstraint deactivateConstraints:self.style.displayingConstraints];
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithValueConstraints];
        [NSLayoutConstraint activateConstraints:self.style.recordingWithNoValueConstraints];
    }
    else
    {
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithNoValueConstraints];
        [NSLayoutConstraint deactivateConstraints:self.style.recordingWithValueConstraints];
        [NSLayoutConstraint activateConstraints:self.style.displayingConstraints];
    }
}

- (void)drawBackground:(NSRect)aDirtyRect
{
    NSRect backgroundFrame = [self centerScanRect:_SRIfRespondsGetProp(self.style, backgroundDrawingGuide, frame, self.bounds)];

    if (NSIsEmptyRect(backgroundFrame) || ![self needsToDrawRect:backgroundFrame])
        return;

    NSImage *left = nil;
    NSImage *center = nil;
    NSImage *right = nil;

    [NSGraphicsContext saveGraphicsState];

    if (self.isRecording)
    {
        left = _SRIfRespondsGet(self.style, bezelRecordingLeft, nil);
        center = _SRIfRespondsGet(self.style, bezelRecordingCenter, nil);
        right = _SRIfRespondsGet(self.style, bezelRecordingRight, nil);
    }
    else
    {
        if (self.isMainButtonHighlighted)
        {
            left = _SRIfRespondsGet(self.style, bezelPressedLeft, nil);
            center = _SRIfRespondsGet(self.style, bezelPressedCenter, nil);
            right = _SRIfRespondsGet(self.style, bezelPressedRight, nil);
        }
        else if (self.enabled)
        {
            left = _SRIfRespondsGet(self.style, bezelNormalLeft, nil);
            center = _SRIfRespondsGet(self.style, bezelNormalCenter, nil);
            right = _SRIfRespondsGet(self.style, bezelNormalRight, nil);
        }
        else
        {
            left = _SRIfRespondsGet(self.style, bezelDisabledLeft, nil);
            center = _SRIfRespondsGet(self.style, bezelDisabledCenter, nil);
            right = _SRIfRespondsGet(self.style, bezelDisabledRight, nil);
        }
    }

    if (left && center && right)
    {
        os_trace_debug("#Developer drawing background using images");
        NSDrawThreePartImage(backgroundFrame, left, center, right, NO, NSCompositeSourceOver, 1.0, self.isFlipped);
    }
    else
    {
        os_trace_debug("#Developer drawing background using color");

        if (self.isOpaque)
            [NSColor.windowBackgroundColor setFill];
        else
            [NSColor.clearColor setFill];

        NSRectFill(NSIntersectionRect(backgroundFrame, aDirtyRect));
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawInterior:(NSRect)aDirtyRect
{
    [self drawLabel:aDirtyRect];

    if (self.isRecording)
    {
        [self drawCancelButton:aDirtyRect];

        if (_objectValue)
            [self drawClearButton:aDirtyRect];
    }
}

- (void)drawLabel:(NSRect)aDirtyRect
{
    NSRect labelFrame = self.style.labelDrawingGuide.frame;

    if (NSIsEmptyRect(labelFrame) || ![self needsToDrawRect:labelFrame])
        return;

    NSString *label = self.drawingLabel;
    NSDictionary *labelAttributes = self.drawingLabelAttributes;

    [NSGraphicsContext saveGraphicsState];
    CGFloat baselineOffset = _SRIfRespondsGet(self.style, baselineLayoutOffsetFromBottom, self.style.baselineDrawingOffsetFromBottom);
    labelFrame.origin.y = NSMaxY(labelFrame) - baselineOffset;
    labelFrame = [self backingAlignedRect:labelFrame options:NSAlignRectFlipped |
                  NSAlignMinXOutward |
                  NSAlignMinYOutward |
                  NSAlignMaxXInward |
                  NSAlignMaxYInward];

    CGFloat minWidth = [labelAttributes[SRMinimalDrawableWidthAttributeName] doubleValue];
    if (labelFrame.size.width >= minWidth)
        [label drawWithRect:labelFrame options:0 attributes:labelAttributes context:nil];

    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawCancelButton:(NSRect)aDirtyRect
{
    NSRect cancelButtonFrame = [self centerScanRect:_SRIfRespondsGetProp(self.style, cancelButtonDrawingGuide, frame, NSZeroRect)];

    if (NSIsEmptyRect(cancelButtonFrame) || ![self needsToDrawRect:cancelButtonFrame])
        return;

    NSImage *image = self.isCancelButtonHighlighted ? _SRIfRespondsGet(self.style, cancelButtonPressed, nil) : _SRIfRespondsGet(self.style, cancelButton, nil);
    if (!image)
        return;

    [NSGraphicsContext saveGraphicsState];
    [image drawInRect:cancelButtonFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawClearButton:(NSRect)aDirtyRect
{
    NSRect clearButtonFrame = [self centerScanRect:_SRIfRespondsGetProp(self.style, clearButtonDrawingGuide, frame, NSZeroRect)];
    if (NSIsEmptyRect(clearButtonFrame) || ![self needsToDrawRect:clearButtonFrame])
        return;

    NSImage *image = self.isClearButtonHighlighted ? _SRIfRespondsGet(self.style, clearButtonPressed, nil) : _SRIfRespondsGet(self.style, clearButton, nil);
    if (!image)
        return;

    [NSGraphicsContext saveGraphicsState];
    [image drawInRect:clearButtonFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)areModifierFlagsValid:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode
{
    aModifierFlags &= SRCocoaModifierFlagsMask;
    __block BOOL allowModifierFlags = YES;

    os_activity_initiate("areModifierFlagsValid:forKeyCode:", OS_ACTIVITY_FLAG_DEFAULT, ^{
        allowModifierFlags = [self areModifierFlagsAllowed:aModifierFlags forKeyCode:aKeyCode];

        if ((aModifierFlags & self.requiredModifierFlags) != self.requiredModifierFlags)
            allowModifierFlags = NO;
    });

    return allowModifierFlags;
}

- (BOOL)areModifierFlagsAllowed:(NSEventModifierFlags)aModifierFlags forKeyCode:(unsigned short)aKeyCode
{
    aModifierFlags &= SRCocoaModifierFlagsMask;
    __block BOOL allowModifierFlags = YES;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __auto_type DelegateShouldUnconditionallyAllowModifierFlags = ^{
        if (!allowModifierFlags && [self.delegate respondsToSelector:@selector(recorderControl:shouldUnconditionallyAllowModifierFlags:forKeyCode:)])
        {
            return [self.delegate recorderControl:self shouldUnconditionallyAllowModifierFlags:aModifierFlags forKeyCode:aKeyCode];
        }
        else if (!allowModifierFlags && [self.delegate respondsToSelector:@selector(shortcutRecorder:shouldUnconditionallyAllowModifierFlags:forKeyCode:)])
        {
            return [self.delegate shortcutRecorder:self shouldUnconditionallyAllowModifierFlags:aModifierFlags forKeyCode:aKeyCode];
        }
        else
            return YES;
    };
#pragma clang diagnostic pop

    os_activity_initiate("areModifierFlagsAllowed:forKeyCode:", OS_ACTIVITY_FLAG_IF_NONE_PRESENT, ^{
        if (aModifierFlags == 0 && !self.allowsEmptyModifierFlags)
            allowModifierFlags = NO;
        else if ((aModifierFlags & self.allowedModifierFlags) != aModifierFlags)
            allowModifierFlags = NO;

        allowModifierFlags = DelegateShouldUnconditionallyAllowModifierFlags();
    });

    return allowModifierFlags;
}

- (void)playAlert
{
    NSBeep();
}

- (void)propagateValue:(id)aValue forBinding:(NSString *)aBinding
{
    NSParameterAssert(aBinding != nil);

    NSDictionary* bindingInfo = [self infoForBinding:aBinding];

    if(!bindingInfo || (id)bindingInfo == NSNull.null)
        return;

    NSObject *boundObject = bindingInfo[NSObservedObjectKey];

    if(!boundObject || (id)boundObject == NSNull.null)
        [NSException raise:NSInternalInconsistencyException format:@"NSObservedObjectKey MUST NOT be nil for binding \"%@\"", aBinding];

    NSString* boundKeyPath = bindingInfo[NSObservedKeyPathKey];

    if(!boundKeyPath || (id)boundKeyPath == NSNull.null)
        [NSException raise:NSInternalInconsistencyException format:@"NSObservedKeyPathKey MUST NOT be nil for binding \"%@\"", aBinding];

    NSDictionary* bindingOptions = bindingInfo[NSOptionsKey];

    if(bindingOptions)
    {
        NSValueTransformer* transformer = [bindingOptions valueForKey:NSValueTransformerBindingOption];

        if(!transformer || (id)transformer == NSNull.null)
        {
            NSString* transformerName = [bindingOptions valueForKey:NSValueTransformerNameBindingOption];

            if(transformerName && (id)transformerName != NSNull.null)
                transformer = [NSValueTransformer valueTransformerForName:transformerName];
        }

        if(transformer && (id)transformer != NSNull.null)
        {
            if([[transformer class] allowsReverseTransformation])
                aValue = [transformer reverseTransformedValue:aValue];
            else
                NSLog(@"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", aBinding, __PRETTY_FUNCTION__);
        }
    }

    if (!_isCompatibilityModeEnabled &&
        ([boundObject isKindOfClass:NSUserDefaults.class] || [boundObject isKindOfClass:NSUserDefaultsController.class]) &&
        [aValue isKindOfClass:SRShortcut.class])
    {
        os_trace_error("#Error The control is bound to NSUserDefaults but is not transformed into an allowed CFPreferences value");
        NSLog(@"WARNING: Shortcut Recroder 2 compatibility mode enabled. Getters of objectValue and NSValueBinding will return an instance of NSDictionary.");
        _isCompatibilityModeEnabled = YES;

        aValue = [aValue dictionaryRepresentation];
    }

    [boundObject setValue:aValue forKeyPath:boundKeyPath];
}

- (void)controlTintDidChange:(NSNotification *)aNotification
{
    [self scheduleControlViewAppearanceDidChange:aNotification];
}

- (void)accessibilityDisplayOptionsDidChange:(NSNotification *)aNotification
{
    [self scheduleControlViewAppearanceDidChange:aNotification];
}

- (void)scheduleControlViewAppearanceDidChange:(nullable id)aReason
{
    if (_notifyStyle == nil || ![_style respondsToSelector:@selector(recorderControlAppearanceDidChange:)])
        // recorderControlAppearanceDidChange: is called whenever _style is created.
        return;

    [NSObject cancelPreviousPerformRequestsWithTarget:_notifyStyle];
    [_notifyStyle setArgument:&aReason atIndex:2];
    [_notifyStyle performSelector:@selector(invokeWithTarget:) withObject:_style afterDelay:0.0 inModes:@[NSRunLoopCommonModes]];
}

#pragma mark NSAccessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (BOOL)isAccessibilityEnabled
{
    return self.isEnabled;
}

- (NSString *)accessibilityLabel
{
    if (self.isRecording)
    {
        _accessibilityRecordingModifierFlags = _currentlyDrawnRecordingModifierFlags;
        return [SRLiteralModifierFlagsTransformer.sharedTransformer transformedValue:@(_accessibilityRecordingModifierFlags)
                                                                     layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
    }
    else
        return super.accessibilityLabel;
}

- (id)accessibilityValue
{
    if (self.isRecording)
        return super.accessibilityValue;
    else
    {
        if (!_objectValue)
            return SRLoc(@"Empty");

        NSString *f = [SRLiteralModifierFlagsTransformer.sharedTransformer transformedValue:@(_objectValue.modifierFlags)
                                                                            layoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
        NSString *c = nil;

        if (self.drawsASCIIEquivalentOfShortcut)
            c = [SRASCIILiteralKeyCodeTransformer.sharedTransformer transformedValue:@(_objectValue.keyCode)];
        else
            c = [SRLiteralKeyCodeTransformer.sharedTransformer transformedValue:@(_objectValue.keyCode)];

        if (f.length > 0)
            return [NSString stringWithFormat:@"%@-%@", f, c];
        else
            return [NSString stringWithFormat:@"%@", c];
    }
}

- (NSString *)accessibilityHelp
{
    return nil;
}

- (NSAccessibilityRole)accessibilityRole
{
    return NSAccessibilityButtonRole;
}

- (NSString *)accessibilityRoleDescription
{
    if (self.isRecording)
        return SRLoc(@"Type shortcut").localizedLowercaseString;
    else
        return SRLoc(@"Shortcut").localizedLowercaseString;
}

- (id)accessibilityHitTest:(NSPoint)aPoint
{
    // NSControl's implementation relies on its cell which is nil for SRRecorderControl.
    return self;
}

- (BOOL)accessibilityPerformPress
{
    return [self beginRecording];
}

- (BOOL)accessibilityPerformCancel
{
    if (self.isRecording)
    {
        [self endRecording];
        return YES;
    }
    else
        return NO;
}

- (BOOL)accessibilityPerformDelete
{
    if (self.isRecording && _objectValue)
    {
        [self clearAndEndRecording];
        return YES;
    }
    else
        return NO;
}

#pragma mark NSEditor

- (BOOL)commitEditing
{
    // Shortcuts recording is atomic (either all or nothing) and there are no pending changes.
    [self discardEditing];
    return YES;
}

- (void)commitEditingWithDelegate:(id)aDelegate didCommitSelector:(SEL)aDidCommitSelector contextInfo:(void *)aContextInfo
{
    BOOL isEditingCommited = [self commitEditing];
    // See AppKit's __NSSendCommitEditingSelector
    NSInvocation *i = [NSInvocation invocationWithMethodSignature:[aDelegate methodSignatureForSelector:aDidCommitSelector]];
    [i setSelector:aDidCommitSelector];
    [i setArgument:(void*)&self atIndex:2];
    [i setArgument:&isEditingCommited atIndex:3];
    [i setArgument:&aContextInfo atIndex:4];
    [i retainArguments];
    [i performSelector:@selector(invokeWithTarget:) withObject:aDelegate afterDelay:0 inModes:@[NSRunLoopCommonModes]];
}

- (BOOL)commitEditingAndReturnError:(NSError * __autoreleasing *)outError
{
    return [self commitEditing];
}

- (void)discardEditing
{
    [self endRecording];
}

#pragma mark NSNibLoading

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    self.objectValue = [SRShortcut shortcutWithCode:0
                                      modifierFlags:NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift | NSEventModifierFlagCommand
                                         characters:@""
                        charactersIgnoringModifiers:@"a"];
}

#pragma mark NSViewToolTipOwner

- (NSString *)view:(NSView *)aView stringForToolTip:(NSToolTipTag)aTag point:(NSPoint)aPoint userData:(void *)aData
{
    if (aTag == _cancelButtonToolTipTag)
        return _SRIfRespondsGet(self.style, cancelButtonTooltip, SRLoc(@"Use old shortcut"));
    else if (aTag == _clearButtonToolTipTag)
        return _SRIfRespondsGet(self.style, clearButtonTooltip, SRLoc("Delete current shortcut"));
    else
        return [super view:aView stringForToolTip:aTag point:aPoint userData:aData];
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aCoder
{
    // Since Xcode 6.x, user can configure xib to Prefer Coder.
    // In that case view will be instantiated with initWithCoder.
    //
    // awakeFromNib cannot be used to set up defaults for IBDesignable,
    // because at the time it's called, it's impossible to know whether properties
    // were set by a user in xib or they are compilation-time defaults.
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self initInternalState];
    }

    return self;
}

#pragma mark NSControl
@dynamic enabled;
@synthesize refusesFirstResponder = _refusesFirstResponder;
@synthesize tag = _tag;

+ (Class)cellClass
{
    return nil;
}

- (NSAttributedString *)attributedStringValue
{
    return [[NSAttributedString alloc] initWithString:self.stringValue];
}

- (void)setAttributedStringValue:(NSAttributedString *)newAttributedStringValue
{
    [self setObjectValue:[SRShortcut shortcutWithKeyEquivalent:newAttributedStringValue.string]];
}

- (NSString *)stringValue
{
    if (!_objectValue)
        return @"";

    __auto_type layoutDirection = self.stringValueRespectsUserInterfaceLayoutDirection ? self.userInterfaceLayoutDirection : NSUserInterfaceLayoutDirectionLeftToRight;
    NSString *flags = [SRSymbolicModifierFlagsTransformer.sharedTransformer transformedValue:@(_objectValue.modifierFlags)
                                                                             layoutDirection:layoutDirection];
    SRKeyCodeTransformer *transformer = nil;

    if (self.drawsASCIIEquivalentOfShortcut)
        transformer = SRASCIILiteralKeyCodeTransformer.sharedTransformer;
    else
        transformer = SRLiteralKeyCodeTransformer.sharedTransformer;

    NSString *code = [transformer transformedValue:@(_objectValue.keyCode)
                         withImplicitModifierFlags:nil
                             explicitModifierFlags:@(_objectValue.modifierFlags)
                                   layoutDirection:layoutDirection];

    if (layoutDirection == NSUserInterfaceLayoutDirectionRightToLeft)
        return [NSString stringWithFormat:@"%@%@", code, flags];
    else
        return [NSString stringWithFormat:@"%@%@", flags, code];
}

- (void)setStringValue:(NSString *)newStringValue
{
    [self setObjectValue:[SRShortcut shortcutWithKeyEquivalent:newStringValue]];
}

- (BOOL)isHighlighted
{
    return self.isMainButtonHighlighted;
}

- (BOOL)abortEditing
{
    [self endRecording];
    return NO;
}

#pragma mark NSView

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (BOOL)isOpaque
{
    return self.style.isOpaque;
}

- (BOOL)allowsVibrancy
{
    return self.style.allowsVibrancy;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setUserInterfaceLayoutDirection:(NSUserInterfaceLayoutDirection)newUserInterfaceLayoutDirection
{
    NSNumber *currentValue = objc_getAssociatedObject(self, @selector(userInterfaceLayoutDirection));

    if (currentValue && currentValue.integerValue == newUserInterfaceLayoutDirection)
        return;

    objc_setAssociatedObject(self,
                             @selector(userInterfaceLayoutDirection),
                             @(newUserInterfaceLayoutDirection),
                             OBJC_ASSOCIATION_RETAIN);
    [self scheduleControlViewAppearanceDidChange:nil];
}

- (NSUserInterfaceLayoutDirection)userInterfaceLayoutDirection
{
    // NSView uses associated objects to track whether default value was overridden.
    // Here the lookup order is altered in the following way
    //     1. View's own value
    //     2. Style's value
    //     3. View's default value that falls back to NSWindow and then NSApp
    NSNumber *currentValue = objc_getAssociatedObject(self, @selector(userInterfaceLayoutDirection));
    if (currentValue)
        return currentValue.integerValue;

    // If there is no style yet, return macOS's default value.
    if (!_isLazilyInitializingStyle && [self.style respondsToSelector:@selector(preferredComponents)])
    {
        __auto_type layoutDirection = self.style.preferredComponents.layoutDirection;
        if (layoutDirection != SRRecorderControlStyleComponentsLayoutDirectionUnspecified)
            return SRRecorderControlStyleComponentsLayoutDirectionToSystem(layoutDirection);
    }

    return super.userInterfaceLayoutDirection;
}

- (void)layout
{
    NSRect oldLabelFrame = self.style.labelDrawingGuide.frame;
    NSRect oldCancelButtonFrame = _SRIfRespondsGetProp(self.style, cancelButtonDrawingGuide, frame, NSZeroRect);
    NSRect oldClearButtonFrame = _SRIfRespondsGetProp(self.style, clearButtonDrawingGuide, frame, NSZeroRect);

    [super layout];

    NSRect newLabelFrame = self.style.labelDrawingGuide.frame;
    NSRect newCancelButtonFrame = _SRIfRespondsGetProp(self.style, cancelButtonDrawingGuide, frame, NSZeroRect);
    NSRect newClearButtonFrame = _SRIfRespondsGetProp(self.style, clearButtonDrawingGuide, frame, NSZeroRect);

    if (!NSEqualRects(oldLabelFrame, newLabelFrame))
    {
        [self setNeedsDisplayInRect:oldLabelFrame];
        [self setNeedsDisplayInRect:newLabelFrame];
    }

    if (!NSEqualRects(oldCancelButtonFrame, newCancelButtonFrame))
    {
        [self setNeedsDisplayInRect:oldCancelButtonFrame];
        [self setNeedsDisplayInRect:newCancelButtonFrame];
    }

    if (!NSEqualRects(oldClearButtonFrame, newClearButtonFrame))
    {
        [self setNeedsDisplayInRect:oldClearButtonFrame];
        [self setNeedsDisplayInRect:newClearButtonFrame];
    }
}

- (void)drawRect:(NSRect)aDirtyRect
{
    [self drawBackground:aDirtyRect];
    [self drawInterior:aDirtyRect];
}

- (void)drawFocusRingMask
{
    if (self.enabled && self.window.firstResponder == self)
        [self.focusRingShape fill];
}

- (NSRect)focusRingMaskBounds
{
    if (self.enabled && self.window.firstResponder == self)
        return self.focusRingShape.bounds;
    else
        return NSZeroRect;
}

- (NSEdgeInsets)alignmentRectInsets
{
    return self.style.alignmentRectInsets;
}

- (NSSize)intrinsicContentSize
{
    return self.style.intrinsicContentSize;
}

- (CGFloat)baselineOffsetFromBottom
{
    return _SRIfRespondsGet(self.style, baselineLayoutOffsetFromBottom, self.style.baselineDrawingOffsetFromBottom);
}

- (CGFloat)firstBaselineOffsetFromTop
{
    return self.style.alignmentGuide.frame.size.height - self.baselineOffsetFromBottom;
}

- (void)updateTrackingAreas
{
    static const NSTrackingAreaOptions TrackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder | NSTrackingEnabledDuringMouseDrag;

    NSRect cancelButtonFrame = _SRIfRespondsGetProp(self.style,
                                                  cancelButtonLayoutGuide,
                                                  frame,
                                                  _SRIfRespondsGetProp(self.style,
                                                                     cancelButtonDrawingGuide,
                                                                     frame,
                                                                     NSZeroRect));
    NSRect clearButtonFrame = _SRIfRespondsGetProp(self.style,
                                                 clearButtonLayoutGuide,
                                                 frame,
                                                 _SRIfRespondsGetProp(self.style,
                                                                    clearButtonDrawingGuide,
                                                                    frame,
                                                                    NSZeroRect));

    if (_mainButtonTrackingArea)
        [self removeTrackingArea:_mainButtonTrackingArea];

    _mainButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                        options:TrackingOptions
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:_mainButtonTrackingArea];

    if (_cancelButtonTrackingArea)
    {
        [self removeTrackingArea:_cancelButtonTrackingArea];
        _cancelButtonTrackingArea = nil;
    }

    if (_clearButtonTrackingArea)
    {
        [self removeTrackingArea:_clearButtonTrackingArea];
        _clearButtonTrackingArea = nil;
    }

    if (_cancelButtonToolTipTag != NSIntegerMax)
    {
        [self removeToolTip:_cancelButtonToolTipTag];
        _cancelButtonToolTipTag = NSIntegerMax;
    }

    if (_clearButtonToolTipTag != NSIntegerMax)
    {
        [self removeToolTip:_clearButtonToolTipTag];
        _clearButtonToolTipTag = NSIntegerMax;
    }

    if (self.isRecording)
    {
        if (!NSIsEmptyRect(cancelButtonFrame))
        {
            _cancelButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:cancelButtonFrame
                                                                     options:TrackingOptions
                                                                       owner:self
                                                                    userInfo:nil];
            [self addTrackingArea:_cancelButtonTrackingArea];
            // Since this method is used to set up tracking rects of aux buttons, the rest of the code is aware
            // it should be called whenever geometry or apperance changes. Therefore it's a good place to set up tooltip rects.
            _cancelButtonToolTipTag = [self addToolTipRect:_cancelButtonTrackingArea.rect owner:self userData:NULL];
        }

        if (_objectValue && !NSIsEmptyRect(clearButtonFrame))
        {
            _clearButtonTrackingArea = [[NSTrackingArea alloc] initWithRect:clearButtonFrame
                                                                    options:TrackingOptions
                                                                      owner:self
                                                                   userInfo:nil];
            [self addTrackingArea:_clearButtonTrackingArea];
            _clearButtonToolTipTag = [self addToolTipRect:_clearButtonTrackingArea.rect owner:self userData:NULL];
        }
    }

    [super updateTrackingAreas];
}

- (void)updateConstraints
{
    [self updateActiveConstraints];
    [super updateConstraints];
}

- (void)prepareForReuse
{
    [self endRecording];
    [super prepareForReuse];
}

- (void)viewWillMoveToWindow:(NSWindow *)aWindow
{
    if (self.window)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:NSWindowDidResignKeyNotification
                                                    object:self.window];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:NSControlTintDidChangeNotification
                                                    object:NSApp];
        [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self
                                                                  name:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification
                                                                object:nil];
    }

    if (aWindow)
    {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(endRecording)
                                                   name:NSWindowDidResignKeyNotification
                                                 object:aWindow];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(controlTintDidChange:)
                                                   name:NSControlTintDidChangeNotification
                                                 object:NSApp];
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self
                                                           selector:@selector(accessibilityDisplayOptionsDidChange:) name:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification
                                                             object:nil];
    }

    [super viewWillMoveToWindow:aWindow];
}

- (void)viewDidChangeBackingProperties
{
    [super viewDidChangeBackingProperties];
    [self scheduleControlViewAppearanceDidChange:nil];
}

- (void)viewDidChangeEffectiveAppearance
{
    [super viewDidChangeEffectiveAppearance];
    [self scheduleControlViewAppearanceDidChange:nil];
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return self.enabled && !self.refusesFirstResponder;
}

- (BOOL)resignFirstResponder
{
    [self endRecording];
    _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    return [super resignFirstResponder];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)anEvent
{
    return YES;
}

- (BOOL)canBecomeKeyView
{
    // SRRecorderControl uses the button metaphor, but buttons cannot become key unless
    // Full Keyboard Access is enabled. Respect this.
    return super.canBecomeKeyView && NSApp.fullKeyboardAccessEnabled;
}

- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

- (void)mouseDown:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseDown:anEvent];
        return;
    }

    NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];
    NSRect cancelButtonFrame = _SRIfRespondsGetProp(self.style,
                                                  cancelButtonLayoutGuide,
                                                  frame,
                                                  _SRIfRespondsGetProp(self.style,
                                                                     cancelButtonDrawingGuide,
                                                                     frame,
                                                                     NSZeroRect));
    NSRect clearButtonFrame = _SRIfRespondsGetProp(self.style,
                                                 clearButtonLayoutGuide,
                                                 frame,
                                                 _SRIfRespondsGetProp(self.style,
                                                                    clearButtonDrawingGuide,
                                                                    frame,
                                                                    NSZeroRect));

    if (self.isRecording)
    {
        if ([self mouse:locationInView inRect:cancelButtonFrame])
        {
            _mouseTrackingButtonTag = _SRRecorderControlCancelButtonTag;
            [self setNeedsDisplayInRect:_SRIfRespondsGetProp(self.style, cancelButtonDrawingGuide, frame, NSZeroRect)];
        }
        else if ([self mouse:locationInView inRect:clearButtonFrame])
        {
            _mouseTrackingButtonTag = _SRRecorderControlClearButtonTag;
            [self setNeedsDisplayInRect:_SRIfRespondsGetProp(self.style, clearButtonLayoutGuide, frame, NSZeroRect)];
        }
        else
            [super mouseDown:anEvent];
    }
    else if ([self mouse:locationInView inRect:self.bounds])
    {
        _mouseTrackingButtonTag = _SRRecorderControlMainButtonTag;
        [self setNeedsDisplay:YES];
    }
    else
        [super mouseDown:anEvent];
}

- (void)mouseUp:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseUp:anEvent];
        return;
    }

    NSRect cancelButtonFrame = _SRIfRespondsGetProp(self.style,
                                                  cancelButtonLayoutGuide,
                                                  frame,
                                                  _SRIfRespondsGetProp(self.style,
                                                                     cancelButtonDrawingGuide,
                                                                     frame,
                                                                     NSZeroRect));
    NSRect clearButtonFrame = _SRIfRespondsGetProp(self.style,
                                                 clearButtonLayoutGuide,
                                                 frame,
                                                 _SRIfRespondsGetProp(self.style,
                                                                    clearButtonDrawingGuide,
                                                                    frame,
                                                                    NSZeroRect));

    if (_mouseTrackingButtonTag != _SRRecorderControlInvalidButtonTag)
    {
        if (!self.window.isKeyWindow)
        {
            // It's possible to receive this event after window resigned its key status
            // e.g. when shortcut brings new window and makes it key.
            [self setNeedsDisplay:YES];
        }
        else
        {
            NSPoint locationInView = [self convertPoint:anEvent.locationInWindow fromView:nil];

            if (_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag &&
                [self mouse:locationInView inRect:self.bounds])
            {
                [self beginRecording];
            }
            else if (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag &&
                     [self mouse:locationInView inRect:cancelButtonFrame])
            {
                [self endRecording];
            }
            else if (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag &&
                     [self mouse:locationInView inRect:clearButtonFrame])
            {
                [self clearAndEndRecording];
            }
        }

        _mouseTrackingButtonTag = _SRRecorderControlInvalidButtonTag;
    }
    else
        [super mouseUp:anEvent];
}

- (void)mouseEntered:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseEntered:anEvent];
        return;
    }

    if ((_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag && anEvent.trackingArea == _mainButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag && anEvent.trackingArea == _cancelButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag && anEvent.trackingArea == _clearButtonTrackingArea))
    {
        [self setNeedsDisplayInRect:anEvent.trackingArea.rect];
    }

    [super mouseEntered:anEvent];
}

- (void)mouseExited:(NSEvent *)anEvent
{
    if (!self.enabled)
    {
        [super mouseExited:anEvent];
        return;
    }

    if ((_mouseTrackingButtonTag == _SRRecorderControlMainButtonTag && anEvent.trackingArea == _mainButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlCancelButtonTag && anEvent.trackingArea == _cancelButtonTrackingArea) ||
        (_mouseTrackingButtonTag == _SRRecorderControlClearButtonTag && anEvent.trackingArea == _clearButtonTrackingArea))
    {
        [self setNeedsDisplayInRect:anEvent.trackingArea.rect];
    }

    [super mouseExited:anEvent];
}

- (void)keyDown:(NSEvent *)anEvent
{
    if (![self performKeyEquivalent:anEvent])
        [super keyDown:anEvent];
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
    __block BOOL result = NO;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __auto_type DelegateCanRecordShortcut = ^(SRShortcut *aShortcut){
        if ([self.delegate respondsToSelector:@selector(recorderControl:canRecordShortcut:)])
            return [self.delegate recorderControl:self canRecordShortcut:aShortcut];
        else if ([self.delegate respondsToSelector:@selector(shortcutRecorder:canRecordShortcut:)])
            return [self.delegate shortcutRecorder:self canRecordShortcut:aShortcut.dictionaryRepresentation];
        else if ([self.delegate respondsToSelector:@selector(control:isValidObject:)])
            return [self.delegate control:self isValidObject:aShortcut];
        else
            return YES;
    };
#pragma clang diagnostic pop

    os_activity_initiate("performKeyEquivalent:", OS_ACTIVITY_FLAG_DEFAULT, ^{
        if (!self.enabled)
        {
            os_trace_debug("The control is disabled -> NO");
            result = NO;
            return;
        }

        if (self.window.firstResponder != self)
        {
            os_trace_debug("The control is not the first responder -> NO");
            result = NO;
            return;
        }

        if (self->_mouseTrackingButtonTag != _SRRecorderControlInvalidButtonTag)
        {
            os_trace_debug("The control is tracking %lu -> NO", self->_mouseTrackingButtonTag);
            result = NO;
            return;
        }

        if (self.isRecording)
        {
            if (anEvent.keyCode == USHRT_MAX)
            {
                // This shouldn't really happen ever, but was rarely observed.
                // See https://github.com/Kentzo/ShortcutRecorder/issues/40
                os_trace_debug("Invalid keyCode -> NO");
                result = NO;
            }
            else if (self.allowsEscapeToCancelRecording &&
                anEvent.keyCode == kVK_Escape &&
                (anEvent.modifierFlags & SRCocoaModifierFlagsMask) == 0)
            {
                os_trace_debug("Cancel via Esc -> YES");
                [self endRecording];
                result = YES;
            }
            else if (self.allowsDeleteToClearShortcutAndEndRecording &&
                    (anEvent.keyCode == kVK_Delete || anEvent.keyCode == kVK_ForwardDelete) &&
                    (anEvent.modifierFlags & SRCocoaModifierFlagsMask) == 0)
            {
                os_trace_debug("Clear via Delete -> YES");
                [self clearAndEndRecording];
                result = YES;
            }
            else if ([self areModifierFlagsValid:anEvent.modifierFlags forKeyCode:anEvent.keyCode])
            {
                SRShortcut *newObjectValue = [SRShortcut shortcutWithCode:anEvent.keyCode
                                                            modifierFlags:anEvent.modifierFlags
                                                               characters:anEvent.characters
                                              charactersIgnoringModifiers:anEvent.charactersIgnoringModifiers];

                BOOL canRecordShortcut = DelegateCanRecordShortcut(newObjectValue);

                if (canRecordShortcut)
                {
                    os_trace_debug("Valid and accepted shortcut -> YES");
                    [self endRecordingWithObjectValue:newObjectValue];
                    result = YES;
                }
                else
                {
                    // Do not end editing and allow the client to make another attempt.
                    os_trace_debug("Valid but rejected shortcut -> YES");
                    result = YES;
                }
            }
            else
            {
                os_trace_debug("Modifier flags %lu rejected -> NO", anEvent.modifierFlags);
                result = NO;
            }
        }
        else if (anEvent.keyCode == kVK_Space)
        {
            os_trace_debug("Begin recording via Space -> YES");
            result = [self beginRecording];
        }
        else
            result = NO;
    });

    return result;
}

- (void)flagsChanged:(NSEvent *)anEvent
{
    if (self.isRecording)
    {
        NSEventModifierFlags modifierFlags = anEvent.modifierFlags & SRCocoaModifierFlagsMask;
        if (modifierFlags != 0 && ![self areModifierFlagsAllowed:modifierFlags forKeyCode:anEvent.keyCode])
            [self playAlert];

        [self setNeedsDisplayInRect:self.style.labelDrawingGuide.frame];
    }

    [super flagsChanged:anEvent];
}


#pragma mark NSObject

+ (void)initialize
{
    if (self == [SRRecorderControl class])
    {
        [self exposeBinding:NSValueBinding];
    }
}

- (Class)valueClassForBinding:(NSBindingName)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding])
        return SRShortcut.class;
    else
        return [super valueClassForBinding:aBinding];
}

- (NSArray<NSAttributeDescription *> *)optionDescriptionsForBinding:(NSBindingName)aBinding
{
    if ([aBinding isEqualToString:NSValueBinding])
    {
        NSAttributeDescription *valueTransformer = [NSAttributeDescription new];
        valueTransformer.name = NSValueTransformerBindingOption;
        valueTransformer.attributeType = NSStringAttributeType;
        valueTransformer.defaultValue = @"";

        NSAttributeDescription *valueTransformerName = [NSAttributeDescription new];
        valueTransformerName.name = NSValueTransformerNameBindingOption;
        valueTransformerName.attributeType = NSStringAttributeType;
        valueTransformerName.defaultValue = @"";

        return @[valueTransformer, valueTransformerName];
    }
    else
        return [super optionDescriptionsForBinding:aBinding];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary<NSKeyValueChangeKey, id> *)aChange context:(void *)aContext
{
    if (aContext == &_SRStyleUserInterfaceLayoutDirectionObservingContext)
    {
        if ([aChange objectForKey:NSKeyValueChangeNotificationIsPriorKey])
            [self willChangeValueForKey:@"userInterfaceLayoutDirection"];
        else
            [self didChangeValueForKey:@"userInterfaceLayoutDirection"];
    }
    else if (aContext == &_SRStyleAppearanceObservingContext)
    {
        __auto_type appearance = [aChange[NSKeyValueChangeNewKey] unsignedIntegerValue];

        if (appearance != SRRecorderControlStyleComponentsAppearanceUnspecified)
            self.appearance = [NSAppearance appearanceNamed:SRRecorderControlStyleComponentsAppearanceToSystem(appearance)];
        else
            self.appearance = nil;
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


#undef _SRIfRespondsGet
#undef _SRIfRespondsGetProp
