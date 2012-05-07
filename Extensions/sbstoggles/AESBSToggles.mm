#import "AESBSToggles.h"
#import "AESBSTogglesCommands.h"
#import "AEToggle.h"

@implementation AESBSToggles

// required initialization
-(id)initWithSystem:(id<SESystem>)system
{
	if ( (self = [super init]) )
	{
		// register all extension classes provided
		[system registerCommand:[AESBSTogglesCommands class]];
        [AEToggle initToggles];
	}
	return self;
}

-(void)dealloc
{
    [AEToggle shutdownToggles];
    [super dealloc];
}

// optional info about extension
-(NSString*)author
{
	return @"K3A";
}
-(NSString*)name
{
	return @"SBSToggles";
}
-(NSString*)description
{
	return @"SBSettings Toggles for AE";
}
-(NSString*)website
{
	return @"ae.k3a.me";
}
-(NSString*)versionRequirement
{
	return @"1.0.2";
}

@end
// vim:ft=objc
