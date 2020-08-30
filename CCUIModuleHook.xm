#import "ccUIClasses.h"
#import "ManagerHook.h"
#import <RemoteLog.h>

BOOL blocking = NO;

%hook CCUIModularControlCenterOverlayViewController
- (_Bool)_dismissalTapGestureRecognizerShouldBegin:(id)arg1{
    if (blocking){blocking = NO; return NO;}else return %orig;
}
%end




%hook CCUIContentModuleContainerView
- (_Bool)pointInside:(struct CGPoint)arg1 withEvent:(id)arg2{
    if (moduleViewController.enabled){ 
        blocking=YES; 
        return NO;
    }
    //else 
    return %orig;
}
%end

void recurseGestureRecognisers(UIView* view,BOOL enabling ){

    if ([view respondsToSelector:NSSelectorFromString(@"gestureRecognizers")]) 
        for (UIGestureRecognizer* recogniser in view.gestureRecognizers){
            recogniser.enabled=enabling;
        }

    for (UIView* subview in view.subviews)
        recurseGestureRecognisers(subview, enabling);
}


%hook CCUIContentModuleContainerView


%new
-(void)disableGestureRecognisers{
    recurseGestureRecognisers(self, NO);
    //for (UIGestureRecognizer* recogniser in self.subviews[0].subviews[0].subviews[0].gestureRecognizers){
    //    recogniser.enabled=NO;
    //}
}

%new
-(void)enableGestureRecognisers{
    recurseGestureRecognisers(self, YES);
    //for (UIGestureRecognizer* recogniser in self.subviews[0].subviews[0].subviews[0].gestureRecognizers){
    //    recogniser.enabled=YES;
    //}
}

%new
-(void)addShakeAnimation{
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

    //  this is some trig to make the shaking look better on big modules, 
    //  it basically means you define distance not angles
    float distanceToWobble = 0.03f;
    float distanceToCorner = sqrt(pow(self.bounds.size.height/2,2) + pow(self.bounds.size.width/2,2));

    //  this uses cosine rule, it assumes the curved part of the circle is flat for ease of use.
    //CGFloat wobbleAngle = 0.04f;
    CGFloat wobbleAngle = acos(((2*pow(distanceToCorner, 2))-(pow(distanceToWobble, 2)))/(2*distanceToCorner*distanceToCorner)) * (180 / M_PI);
    NSValue* valLeft = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(wobbleAngle, 0.0f, 0.0f, 1.0f)];
    NSValue* valRight = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-wobbleAngle, 0.0f, 0.0f, 1.0f)];
    animation.values = [NSArray arrayWithObjects:valLeft, valRight, nil];
    //animation.beginTime = CACurrentMediaTime() + excc;
    animation.autoreverses = YES;
    animation.duration = 0.125;
    animation.repeatCount = HUGE_VALF;
    [[self layer] removeAnimationForKey:@"position"];
    [[self layer] addAnimation:animation forKey:@"position"];
}

%new
-(void)removeShakeAnimation{
    [[self layer] removeAnimationForKey:@"position"];
}

%new
-(void)clickedRemoveButton{
    // maybe show confirmation view?
    // althogh if the adding units back system isnt to bad it might still work without
    RLog(@"ls");
    NSMutableDictionary *plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/ControlCenter/ModuleConfiguration_CCSupport.plist"];
    NSMutableArray* value = [plistDic objectForKey:@"module-identifiers"];
    [value removeObjectAtIndex:[value indexOfObject:self.moduleIdentifier]];
    //RLog(@"%@", value[[value indexOfObject:self.moduleIdentifier]]); 
    //CCUIModuleSettingsManager* manager = MSHookIvar<id>(moduleViewController, "_settingsManager");
    UIView* view = self;
    [UIView animateWithDuration:0.2
                     animations:^{view.transform = CGAffineTransformMakeScale(0.4, 0.4); view.alpha = 0.01;}
                     completion:^(BOOL finished){[plistDic writeToFile:@"/var/mobile/Library/ControlCenter/ModuleConfiguration_CCSupport.plist" atomically:YES];
                                }];
}

%new
-(void)animatedAddCrossButton{
    UIButton *CoverButton = [[UIButton alloc] init];
    [self setBackgroundColor:[UIColor clearColor]];
    [self addSubview:CoverButton];

    
    UIButton *cancelButton = [%c(SBXCloseBoxView) buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton addTarget:self action:@selector(clickedRemoveButton) forControlEvents:UIControlEventTouchUpInside];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedRemoveButton)];
    [cancelButton addGestureRecognizer:tap];
    //[self addGestureRecognizer:tap];
    [cancelButton setFrame:CGRectMake(-11, -11, 26, 26)];
    //[cancelButton setTitle:@"x" forState:UIControlStateNormal];
    [cancelButton setTag:0010];
    //cancelButton.contentEdgeInsets = UIEdgeInsets(13, 13, 13, 13);
    cancelButton.alpha = 0.01;
    id view = [self viewWithTag:0010];
    while (view != nil){
        [view removeFromSuperview];
        view = [self viewWithTag:0010];
    }
    [self addSubview:cancelButton];
    UIView* newSubView = [self viewWithTag:0010];
    newSubView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.2
                     animations:^{newSubView.transform = CGAffineTransformMakeScale(1, 1); newSubView.alpha = 0.8;}
                     completion:^(BOOL finished){}];


}

%new
-(void)animatedRemoveCrossButton{
    UIView* view = [self viewWithTag:0010];
    [UIView animateWithDuration:0.2
                     animations:^{view.transform = CGAffineTransformMakeScale(0.4, 0.4); view.alpha = 0.01;}
                     completion:^(BOOL finished){[self removeCrossButton];}];
}

%new
-(void)removeCrossButton{
    id view = [self viewWithTag:0010];
    [view removeFromSuperview];
}

%end
