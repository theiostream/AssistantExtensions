#import "SiriObjects.h"

@interface AEStandardCommands : NSObject<SECommand> {
	id<SESystem> _system;
}
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)allApplications;
@end

@interface SBProcess : NSObject
- (BOOL)isRunning;
@end

@interface SBApplication : NSObject
- (NSString *)displayName;
- (SBProcess *)process;
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (void)_hideKeyboard;
- (void)lockFromSource:(int)source;
- (int)curvedBatteryCapacityAsPercentage;
@end

@interface SBAwayController : NSObject
+ (id)sharedAwayController;
- (BOOL)isDeviceLocked;
- (BOOL)isPasswordProtected;
@end

@interface SBAppSwitcherController : NSObject
- (void)_removeApplicationFromRecents:(id)app;
@end

@interface UIApplication (AEStandardSpringBoard)
- (void)powerDown;
- (void)reboot;
@end

@interface SBBrightnessController : NSObject
+ (id)sharedBrightnessController;
- (void)setBrightnessLevel:(float)level;
@end