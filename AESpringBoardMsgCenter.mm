//
//  AESpringBoardMsgCenter.m
//  AssistantExtensions
//
//  Created by Kexik on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include <notify.h>
#import "OS5Additions.h"
#include <substrate.h>

#import "AESpringBoardMsgCenter.h"
#include "main.h"
#include "AEStringAdditions.h"
#include "AESupport.h"
#include "AEExtension.h"

static void ReloadPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[AESpringBoardMsgCenter sharedInstance] reloadPrefs];
}

static BOOL s_firstRequestMade = NO;
static BOOL buildMessageLock = NO;

static NSMutableArray* s_tokens = nil;
static NSMutableSet* s_handled_refs = nil;

void SBCenterAssistantDismissed() {
    s_firstRequestMade = NO;
    buildMessageLock = NO;
}

void RequestCompleted() {
    // Do nothing. Just keep this function to avoid meh.
    //s_reqHandledByExtension = false;
}

static bool HandleSpeech(NSString* refId, NSString* text, NSArray* tokens, NSSet* tokenset) {
    // inform all extensions that the first request has been made and assistant is activated
    if (!s_firstRequestMade) {
        s_firstRequestMade = YES;
        
        for (AEExtension* ex in [AEExtension allExtensions])
            [ex callAssistantActivated];
    }
    
    return HandleSpeechExtensions(refId, text, tokens, tokenset);
}

static AESpringBoardMsgCenter* s_inst = nil;
@implementation AESpringBoardMsgCenter
+ (AESpringBoardMsgCenter*)sharedInstance {
    return s_inst;
}

-(NSDictionary*)handleServer2Client:(NSString*)name userInfo:(NSDictionary*)userInfo {   
    NSDictionary* object = [userInfo objectForKey:@"object"];
    
    NSNumber* tweakEnabled = [self prefForKey:@"enabled"];
    if (tweakEnabled && ![tweakEnabled boolValue]) {
        NSLog(@"AE: Disabled - not doing anything");
        return [NSDictionary dictionaryWithObjectsAndKeys:object,@"object", nil]; // send normally
    }
    
    NSString* pClass = [object objectForKey:@"class"];
    NSString* pRefId = [object objectForKey:@"refId"];
    if (!pRefId) pRefId = [object objectForKey:@"aceId"];
	NSDictionary* pProps = [object objectForKey:@"properties"];
    
    // check whether it is already handled ref
    NSLog(@"AE: pRefId: %@", pRefId);
    if ([s_handled_refs containsObject:pRefId]) {
        NSLog(@"AE: Ignoring original server->client %@ object.", pClass);
        return [NSDictionary dictionaryWithObjectsAndKeys:nil,@"object", nil];
    }
    
    // handle message locks
   	if ([pClass isEqualToString:@"DomainObjectCreate"])
   		buildMessageLock = YES;
   		
   	else if (buildMessageLock && ([pClass isEqualToString:@"DomainObjectCommit"] || [pClass isEqualToString:@"DomainObjectCancel"]))
   		buildMessageLock = NO;
    
    // try raw objects extension first
    for (AEExtension* ex in [AEExtension allExtensions]) {
        if (object && [ex handlesServerToClientClass:pClass]) {
            NSMutableDictionary* deepMutableCopy = (NSMutableDictionary*)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)object, kCFPropertyListMutableContainers);
            [deepMutableCopy autorelease];
            
            object = [ex serverToClient:deepMutableCopy context:[AEContext contextWithRefId:pRefId]];
            return [NSDictionary dictionaryWithObjectsAndKeys:object,@"object", nil];
        }
    }
    
    // we will intercept SpeechRecognized only
    if ([pClass isEqualToString:@"SpeechRecognized"]) {
        IPCCallResponse(@"me.k3a.AssistantExtensions.ad", @"Send2Client", [NSDictionary dictionaryWithObjectsAndKeys:object,@"object", nil]);
        if (buildMessageLock)
   			return [NSDictionary dictionaryWithObjectsAndKeys:nil,@"object", nil];
        
        [s_tokens removeAllObjects];
        
        //NSLog(@"===> RECOGNIT. PROPS: %@", [p1 properties]);
        NSArray* phrases = [[[pProps objectForKey:@"recognition"] objectForKey:@"properties"] objectForKey:@"phrases"];
        for (NSDictionary* phrase in phrases)
        {
            NSArray* interpretations = [[phrase objectForKey:@"properties"] objectForKey:@"interpretations"];
            NSMutableArray* phraseTokens = [NSMutableArray array];
            float bestInterpretationsScore = -1;
            
            // ...for all interpretations
            for (NSDictionary* interp in interpretations)
            {
                float currInterpretationsScore = 0;
                
                // ... for all tokens in interpretation
                NSArray* tokens = [[interp objectForKey:@"properties"] objectForKey:@"tokens"];
                NSMutableArray* interpTokens = [NSMutableArray array];
                
                for (id tok in tokens)
				{
                    int confidenceScore = [[[tok objectForKey:@"properties"] objectForKey:@"confidenceScore"] intValue];
                    NSString *tokText = [[tok objectForKey:@"properties"] objectForKey:@"text"];
                    if (tokText) 
                    { 
                        [interpTokens addObject:[tokText lowercaseString]];
                        currInterpretationsScore = confidenceScore;
                    }
                }
                
                // has the current interpretation better score? replace the phrase tokens with this one
                if ([tokens count]>0 && interpTokens)
                {
                    currInterpretationsScore /= [tokens count];
                    if (currInterpretationsScore > bestInterpretationsScore) 
                    {
                        [phraseTokens removeAllObjects];
                        [phraseTokens addObjectsFromArray:interpTokens];
                        bestInterpretationsScore = currInterpretationsScore;
                    }
                }
            }
            
            // add tokens of the best interpretation of the currnt phrase to the list of tokens
            if (phraseTokens) [s_tokens addObjectsFromArray:phraseTokens];
        }
        
        // create or get a sentence
        NSMutableString* textRaw = [NSMutableString string];
        for (NSString* tok in s_tokens)
        {
            [textRaw appendFormat:@"%@ ", tok];
            // TODO: probably create from interpretations above, also with proper case and without a space at the end
        }
        NSString* text = [textRaw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // SiriServer multi-word token fix
        [s_tokens setArray:[text componentsSeparatedByString:@" "]];
        
        NSLog(@"AE: ==> RECOGNIZED TOKENS: %@", s_tokens);
        
        NSSet* tokenset = [NSSet setWithArray:s_tokens];
        if (HandleSpeech(pRefId, text, s_tokens, tokenset))
        {
            // add this refId to the list of handled refs and ignore additional server responses for it
            NSLog(@"(theiostream) HandleSpeech was a success.");
            if (pRefId) [s_handled_refs addObject:pRefId];
        }
        
        return [NSDictionary dictionaryWithObjectsAndKeys:nil,@"object", nil]; // we already sent the 'SpeechRecognized' object
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:object,@"object", nil]; // send normally
}

-(NSDictionary*)handleClient2Server:(NSString*)name userInfo:(NSDictionary*)userInfo {
    NSDictionary* object = [userInfo objectForKey:@"object"];
    NSString* clsName = [object objectForKey:@"class"];
    NSString* refId = [object objectForKey:@"refId"];
    if (!refId) refId = [object objectForKey:@"aceId"];
    
    // is tweak disabled?
    NSNumber* tweakEnabled = [self prefForKey:@"enabled"];
    if (tweakEnabled && ![tweakEnabled boolValue])
    {
        NSLog(@"AE: Disabled - not doing anything");
        return [NSDictionary dictionaryWithObjectsAndKeys:object,@"object", nil];
    }
    
    //NSLog(@"AE: handleClient2Server: %@", userInfo);
    
    // check whether it is already handled ref
    if ([clsName isEqualToString:@"SetRequestOrigin"])
    {
        NSLog(@"AE: Storing assistant location data.");
        NSDictionary* props = [object objectForKey:@"properties"];
        locationData.valid = true;
        locationData.altitude = [[props objectForKey:@"altitude"] floatValue];
        locationData.direction = [[props objectForKey:@"direction"] floatValue];
        locationData.longitude = [[props objectForKey:@"longitude"] floatValue];
        locationData.age = [[props objectForKey:@"age"] intValue];
        locationData.timestamp = [[NSDate date] timeIntervalSince1970] - locationData.age;
        locationData.speed = [[props objectForKey:@"speed"] floatValue];
        locationData.latitude = [[props objectForKey:@"latitude"] floatValue];
        locationData.verticalAccuracy = [[props objectForKey:@"verticalAccuracy"] floatValue];
        locationData.horizontalAccuracy = [[props objectForKey:@"horizontalAccuracy"] floatValue];
    }
    
    // check whether it is already handled ref
    if ([s_handled_refs containsObject:refId])
    {
        NSLog(@"AE: Ignoring original client->server %@ object.", clsName);
        return [NSDictionary dictionaryWithObjectsAndKeys:nil,@"object", nil];
    }
    
    // try raw objects extension first
    for (AEExtension* ex in [AEExtension allExtensions]) {
        if ([ex handlesClientToServerClass:clsName]) {
            NSMutableDictionary* deepMutableCopy = (NSMutableDictionary*)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)object, kCFPropertyListMutableContainers);
            [deepMutableCopy autorelease];
            
            object = [ex clientToServer:deepMutableCopy context:[AEContext contextWithRefId:refId]];
            return [NSDictionary dictionaryWithObjectsAndKeys:object,@"object", nil];
        }
    }
    
    if (clsName && [clsName isEqualToString:@"StartCorrectedSpeechRequest"]) {
        NSString* refId = [object objectForKey:@"refId"];
        if (!refId || [refId length] == 0) refId = [object objectForKey:@"aceId"];
        
        NSString* utterance = [[[object objectForKey:@"properties"] objectForKey:@"utterance"] lowercaseString];
        NSArray* tokens = [utterance componentsSeparatedByString:@" "];
        NSSet* tokenset = [NSSet setWithArray:tokens];
        
        NSLog(@"AE: Trying to handle user-corrected request '%@'", utterance);
        
        // try to handle user-corrected speech request
        if (HandleSpeech(refId, utterance, tokens, tokenset)) {
            // handled
            NSLog(@"[AE] Client->server returning nil (theiostream)");
            return [NSDictionary dictionaryWithObjectsAndKeys:nil,@"object", nil];
        }
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:object,@"object", nil];
}

-(NSDictionary*)handleDismissAssistant:(NSString*)name userInfo:(NSDictionary*)userInfo {
    NSLog(@"AE: Hiding the assistant");
    static Class _SBAssistantController = objc_getClass("SBAssistantController");
    [(SBAssistantController*)[_SBAssistantController sharedInstance] dismissAssistant];
	return nil;
}

-(NSDictionary*)handleActivateAssistant:(NSString*)name userInfo:(NSDictionary*)userInfo {
    NSLog(@"AE: Activating the assistant");
    static Class _SBAssistantController = objc_getClass("SBAssistantController");
    if ([_SBAssistantController preferenceEnabled] && [_SBAssistantController shouldEnterAssistant]) {
        [[UIApplication sharedApplication] activateAssistantWithOptions:nil withCompletion:nil];
    }
    
	return nil;
}

-(NSDictionary*)handleSay:(NSString*)name userInfo:(NSDictionary*)userInfo {
    AESay([userInfo objectForKey:@"text"], [userInfo objectForKey:@"leng"]);
	return nil;
}

-(NSDictionary*)handleGotLocation:(NSString*)name userInfo:(NSDictionary*)userInfo {
    NSDictionary* resp = userInfo;
    if ([[resp objectForKey:@"result"] boolValue]) {
        NSDictionary* loc = [resp objectForKey:@"location"];
        unsigned long nowTimestamp = [[NSDate date] timeIntervalSince1970];
        
        locationData.valid = YES;
        locationData.altitude = [[loc objectForKey:@"altitude"] floatValue];
        locationData.direction = [[loc objectForKey:@"direction"] floatValue];
        locationData.longitude = [[loc objectForKey:@"longitude"] floatValue];
        locationData.timestamp = [[loc objectForKey:@"timestamp"] unsignedLongValue];
        locationData.speed = [[loc objectForKey:@"speed"] floatValue];
        locationData.latitude = [[loc objectForKey:@"latitude"] floatValue];
        locationData.verticalAccuracy = [[loc objectForKey:@"verticalAccuracy"] floatValue];
        locationData.horizontalAccuracy = [[loc objectForKey:@"horizontalAccuracy"] floatValue];
        locationData.age = nowTimestamp - locationData.timestamp;
    }
	
	return nil;
}

- (NSDictionary*)handleSubmitQuery:(NSString*)name userInfo:(NSDictionary*)userInfo {
    static Class _SBAssistantController = objc_getClass("SBAssistantController");
    
    NSString* query = [userInfo objectForKey:@"query"];
    
    NSString* refId = @"00000000-0000-0000-0000-000000000000";
    /*NSArray* tokens = [query componentsSeparatedByString:@" "];
    NSSet* tokenset = [NSSet setWithArray:tokens];
    
    NSLog(@"AE: Trying to handle IPC request '%@'", query);
    
    // try to handle user-corrected speech request
    if (HandleSpeech(refId, query, tokens, tokenset))
    {
        // handled
        return nil;
    }
    
    [(SBAssistantController*)[_SBAssistantController sharedInstance] _submitQuery:query];*/
    
    SBAssistantController* ac = (SBAssistantController*)[_SBAssistantController sharedInstance];
    AFConnection* conn = [ac _connection];
    
    //[conn startRequestWithText:query timeout:15];
    [conn startRequestWithCorrectedText:query forSpeechIdentifier:refId];
    //[ac _startProcessingRequest];
    [ac expectsFaceContact];
    
    
    return nil;
}

//---------------
- (SOLocationData)getLocationData:(NSString*)refId  showReflection:(BOOL)show {
    unsigned long nowTimestamp = [[NSDate date] timeIntervalSince1970];
    locationData.age = nowTimestamp - locationData.timestamp;
    
    if (!locationData.valid || locationData.age>60) {
        locationData.valid = false;
        
        if (show) {
            NSString* checkingText = @"Checking your location...";
            AESendToClient(SOCreateAceAddViewsUtteranceView(refId, checkingText, checkingText, @"Reflection", NO, NO));
        }
        
        IPCCall(@"me.k3a.AssistantExtensions.ad", @"GetLocation", nil);
    }
    
    else
        NSLog(@"AE: getLocationData: Returning cached data %d seconds old", locationData.age);
    
    // wait a bit for the location
    int seconds = 0;
    while (!locationData.valid && seconds++ < 10) {
        sleep(1);
    }

    return locationData;
}

- (void)ignoreRestOfRequest:(NSString*)refId {
    if (refId) [s_handled_refs addObject:refId];
}

- (NSDictionary *)handleGetExtensions:(NSString *)name withUserInfo:(NSDictionary *)userInfo  {
	NSMutableArray *ret = [NSMutableArray array];
	
	NSArray *allExtensions = [AEExtension allExtensions];
	for (AEExtension* ext in allExtensions) {
		BOOL hp = [ext hasPreferenceBundle];
		
		NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
		[info setObject:[ext displayName] forKey:@"DisplayName"];
		[info setObject:[NSNumber numberWithBool:[ext enabled]] forKey:@"Enabled"];
		[info setObject:[ext iconPath] forKey:@"IconPath"];
		[info setObject:[NSNumber numberWithBool:hp] forKey:@"HasPreferenceBundle"];
		if (hp) [info setObject:[ext preferenceBundle] forKey:@"PreferenceBundle"];
		[info setObject:[ext pathToInfoDictionary] forKey:@"PathToInfoPlist"];
        [info setObject:[ext author] forKey:@"Author"];
        [info setObject:[ext website] forKey:@"Website"];
        [info setObject:[ext version] forKey:@"Version"];
        [info setObject:[ext description] forKey:@"Description"];
        [info setObject:[ext identifier] forKey:@"Identifier"];
		
		[ret addObject:info];
	}

	return [NSDictionary dictionaryWithObject:ret forKey:@"Extensions"];
}

- (void)reloadPrefs {
    [prefs release];
    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.k3a.AssistantExtensions.plist"];
    if (!prefs)
        NSLog(@"AE: Failed to load prefs");
    else
        NSLog(@"AE: Prefs loaded");
}

-(id)prefForKey:(NSString *)name {
    return [prefs objectForKey:name];
}

- (id)init {
	if ((self = [super init])) {
        NSLog(@"[AssistantExtensions] Initializing SpringBoard message center.");
        
        s_inst = self;
        
        s_tokens = [[NSMutableArray alloc] init];
        s_handled_refs = [[NSMutableSet alloc] init];
        locationData.valid = false;
        
        [AEExtension initExtensions];
        
        // init center
		center = [[CPDistributedMessagingCenter centerNamed:@"me.k3a.AssistantExtensions"] retain];
		[center runServerOnCurrentThread];
        
        [center registerForMessageName:@"Server2Client" target:self selector:@selector(handleServer2Client:userInfo:)];
        [center registerForMessageName:@"Client2Server" target:self selector:@selector(handleClient2Server:userInfo:)];
        [center registerForMessageName:@"ActivateAssistant" target:self selector:@selector(handleActivateAssistant:userInfo:)];
        [center registerForMessageName:@"DismissAssistant" target:self selector:@selector(handleDismissAssistant:userInfo:)];
        [center registerForMessageName:@"SubmitQuery" target:self selector:@selector(handleSubmitQuery:userInfo:)];
        [center registerForMessageName:@"Say" target:self selector:@selector(handleSay:userInfo:)];
        [center registerForMessageName:@"GotLocation" target:self selector:@selector(handleGotLocation:userInfo:)];
        [center registerForMessageName:@"AllExtensions" target:self selector:@selector(handleGetExtensions:withUserInfo:)];
        
        // prefs notification observer
        [self reloadPrefs];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, ReloadPrefs, CFSTR("me.k3a.AssistantExtensions/reloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	}
    
	return self;
}

- (void)dealloc {
    [AEExtension shutdownExtensions];
    
    [s_tokens release];
    [s_handled_refs release];
    
	[center release];
	[super dealloc];
}
@end
