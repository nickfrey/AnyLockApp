@class SBApplication, SBAwayLockBar;

#import <substrate.h>
#import "SBApplicationController.h"

static BOOL isUnlockingForCustomApp;

%hook SBAwayController

- (void)activateCamera {
	NSDictionary *settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.nickf.anylockapp.plist"];
	NSString *displayIdentifier = [settingsDictionary objectForKey:@"openApp"];
	if (!displayIdentifier || [displayIdentifier isEqualToString:@"com.apple.camera"]) {
	   %orig;
	} else {
	   isUnlockingForCustomApp = YES;
	   [self unlockWithSound:NO];
	}
}

- (void)_finishedUnlockAttemptWithStatus:(BOOL)fp8 {
	%orig;
	if(isUnlockingForCustomApp == YES && fp8 == YES) {
	    isUnlockingForCustomApp = NO;

	    NSDictionary *settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.nickf.anylockapp.plist"];
	    NSString *displayIdentifier = [settingsDictionary objectForKey:@"openApp"];

	    if([displayIdentifier rangeOfString:@"com.apple.webclip"].location != NSNotFound) {
	        SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:displayIdentifier];
   	        [[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:application];
	   	application = nil;
	    } else {
		SBIcon* webclip = [[%c(SBIconModel) sharedInstance] leafIconForIdentifier:displayIdentifier];
		[webclip launchFromViewSwitcher];
		webclip = nil;
	    }
	}
}

- (void)didAnimateLockKeypadOut {
	%orig;
	isUnlockingForCustomApp = NO;
}

%end

%hook SBAwayLockBar 

- (void)setShowsCameraButton:(BOOL)fp8 {
	%orig;
	UIButton* &camButton = MSHookIvar<UIButton*>(self, "_cameraButton");

	NSDictionary *settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.nickf.anylockapp.plist"];
	NSString *displayIdentifier = [settingsDictionary objectForKey:@"openApp"];
	BOOL showAppIcon = ![[settingsDictionary objectForKey:@"hideAppIcon"] boolValue];

	if(displayIdentifier && ![displayIdentifier isEqualToString:@"com.apple.camera"]) {
	  if(showAppIcon) {
	     if([camButton viewWithTag:92348] != nil) {
		[((UIImageView*)[camButton viewWithTag:92348]) setImage:[[NSClassFromString(@"ALApplicationList") sharedApplicationList] iconOfSize:59 forDisplayIdentifier:displayIdentifier]];
	     } else {
		UIImageView *appIconView = [[%c(UIImageView) alloc] initWithFrame:CGRectMake(10, 10, 32, 32)];
		appIconView.image = [[NSClassFromString(@"ALApplicationList") sharedApplicationList] iconOfSize:59 forDisplayIdentifier:displayIdentifier];
		appIconView.tag = 92348;
		appIconView.userInteractionEnabled = NO;
		appIconView.exclusiveTouch = NO;
		[camButton addSubview:appIconView];
		[appIconView release];
	     }
	  } else {
	     if([camButton viewWithTag:92348] != nil) [(UIView*)[camButton viewWithTag:92348] removeFromSuperview];
	  }
	}
}

%end