// iLockMyKids Source Code
// XXX: wtf is iLockMyKids?

// XXX: I hate HOOK
// XXX: %hook FTW!

#import "SiriObjects_private.h"
#import "OS5Additions.h"
#import <objc/runtime.h>

#import "main.h"
#import "shared.h"
#import "AESupport.h"
#import "AESpringBoardMsgCenter.h"
#import "AEAssistantdMsgCenter.h"

id AECreateAceObjectFromDictionary(NSDictionary *dict) {
	id ctx = [[[objc_getClass("BasicAceContext") alloc] init] autorelease];
    id obj = [objc_getClass("AceObject") aceObjectWithDictionary:dict context:ctx];
    
    return obj;
}

static ADSession *s_lastSession = nil;
%group ADHooks
%hook ADSession
- (void)_handleAceObject:(id)aceObj {
    s_lastSession = self;
    
    NSDictionary* dict = [aceObj dictionary];
    NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions", @"Server2Client", [NSDictionary dictionaryWithObject:dict forKey:@"object"]);
    NSDictionary* respObj = [resp objectForKey:@"object"];
    
    if (respObj) %orig(AECreateAceObjectFromDictionary(respObj));
    else		 %orig;
}

- (void)sendCommand:(id)cmd {
    s_lastSession = self;
    
    NSDictionary* dict = [cmd dictionary];
    NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions", @"Client2Server", [NSDictionary dictionaryWithObject:dict forKey:@"object"]);
    NSDictionary* respObj = [resp objectForKey:@"object"];
    
    if (respObj) %orig(AECreateAceObjectFromDictionary(respObj));
    else		 %orig;
}
%end
%end

%hook BasicAceContext
- (id)init {
    // TODO: maybe cache and use only one context?
    if ((self = %orig))
    	[self addAcronym:@"SAK3AExtension" forGroup:@"me.k3a.ace.extension"];
        
    return self;
}
%end

#pragma mark - HELPER FUNCTIONS ---------------------------------------------------------------

// Convert processed dictionary into new AceObject and call original ADSession functions.
BOOL SessionSend(int type, NSDictionary *dict) {
	if (!s_lastSession) return NO;
	if (!dict)			return NO;
    
    id obj = AECreateAceObjectFromDictionary(dict);
    if (!obj) return NO;
    
    if (type == 0)
    	_logos_orig$ADHooks$ADSession$_handleAceObject$(s_lastSession, @selector(_handleAceObject:), obj);
    else if (type == 1)
    	_logos_orig$ADHooks$ADSession$sendCommand$(s_lastSession, @selector(sendCommand:), obj);
    
    return YES;
}

#pragma mark - INITIALIZATION CODE ---------------------------------------------------------------

static void Shutdown() {
    NSLog(@"[AssistantExtensions] assistantd exited. Shutting down.");
    AESupportShutdown();
    
    //[[AESpringBoardMsgCenter sharedInstance] release];
    //[[AEAssistantdMsgCenter sharedInstance] release];
}

%ctor {
    // Init
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
	// bundle identifier
	NSString* bundleIdent = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"[AssistantExtensions] Loading into %@", bundleIdent);
    
    %init;
    
    if ([bundleIdent isEqualToString:@"com.apple.springboard"]) {
        s_inSB = YES;
        //sleep(2); // just in case (to avoid reboot crashes), probably can be removed later TODO

        [[AESpringBoardMsgCenter alloc] init];
        AESupportInit();
    }
    
    else if ([bundleIdent isEqualToString:@"com.apple.AssistantServices"]) {   
        %init(ADHooks);
        
        [[AEAssistantdMsgCenter alloc] init];
        atexit(&Shutdown);
    }
    
    [pool drain];
}