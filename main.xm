// iLockMyKids Source Code
// XXX: wtf is iLockMyKids?

// XXX: I hate HOOK
// XXX: %hook FTW!

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "SiriObjects_private.h"
#import "OS5Additions.h"

#import <locale.h>
#import <objc/runtime.h>
#include <substrate.h>

#import "main.h"
#import "shared.h"
#import "AESupport.h"

// concrete implementations
#include "AEExtension.h"

#import "AESpringBoardMsgCenter.h"
#import "AEAssistantdMsgCenter.h"

static NSMutableArray* s_regCls = nil; // class acronyms
static bool s_regDone = false; // whether acronyms are registered

bool s_inSB = false;
bool InSpringBoard()
{
    return s_inSB;
}

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
    s_regDone = true;
    
    id orig = %orig;
    [self addAcronym:@"SAK3AExtension" forGroup:@"me.k3a.ace.extension"];
    
    // needed only for custom acronyms for custom AceObjects
    /*for (NSDictionary* dict in s_regCls)
    {
        [self addAcronym:[dict objectForKey:@"acronym"] forGroup:[dict objectForKey:@"group"]];
        NSLog(@"...adding acronym %@ for group %@", [dict objectForKey:@"acronym"], [dict objectForKey:@"group"]);
    }*/
        
    return orig;
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

// ##### ACRONYMS

bool RegisterAcronymImpl(NSString* acronym, NSString* group)
{
    if (s_regDone)
    {
        NSLog(@"AE ERROR: You need to call this method from the initialize() function!");
        return false;
    }
    
    [s_regCls addObject:[NSDictionary dictionaryWithObjectsAndKeys:acronym,@"acronym", group,@"group", nil]];
    return true;
}

// springboard side
NSArray* GetAcronyms(){ s_regDone=true; NSLog(@"++++++++++ SENDING %u acronyms!", [s_regCls count]); return s_regCls; };

// assistantd side
/*static void CopyAcronymsFromSpringboardToAssistantd()
{
    NSArray* acronyms = [[[CPDistributedMessagingCenter centerNamed:@"me.k3a.AssistantExtensions"] sendMessageAndReceiveReplyName:@"GetAcronyms" userInfo:nil] objectForKey:@"acronyms"];
    if (acronyms) 
    {
        NSLog(@"++++++++++ RECEIVED %u acronyms!", [acronyms count]);
    
        [s_regCls autorelease];
        s_regCls = [acronyms mutableCopy];
    }
}*/

// ##### END ACRONYMS

#pragma mark - INITIALIZATION CODE ---------------------------------------------------------------

static void Shutdown() {
    NSLog(@"[AssistantExtensions] assistantd exited. Shutting down.");

    [s_regCls release];
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
    
    s_regCls = [[NSMutableArray alloc] init];
    
    %init;
    
    if ([bundleIdent isEqualToString:@"com.apple.springboard"]) {
        s_inSB = true;
        //sleep(2); // just in case (to avoid reboot crashes), probably can be removed later TODO

        [[AESpringBoardMsgCenter alloc] init];
        AESupportInit(true);
    }
    
    else if ([bundleIdent isEqualToString:@"com.apple.AssistantServices"]) {   
        %init(ADHooks);
        
        //CopyAcronymsFromSpringboardToAssistantd(); // only needed for custom AceObjects
        
        [[AEAssistantdMsgCenter alloc] init];
        AESupportInit(false);
        
        atexit(&Shutdown);
    }
    
    [pool drain];
}