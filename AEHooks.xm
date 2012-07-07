/*%%
%% AEHooks.xm
%% Logified hooks for AssistantExtensions
%%
%% Created by theiostream on 17/4/2012
%% Do not fear, the HOOK dictatorship time is over!
%%*/

/*%
% TODO:
% - Hook SBAssistantUIPluginManager instead of creating .assistntUIBundle
% - UI improvements for AssistantGuide
% - Add AEDevHelper hooks to here
%*/

//############### Declarations

#import "AESpringBoardMsgCenter.h"
#import "AEAssistantdMsgCenter.h"
#import "AEExtension.h"
#import "AESupport.h"
#import "main.h"

static ADSession *s_lastSession = nil;

id AECreateAceObjectFromDictionary(NSDictionary *dict);

//############### SpringBoard Hooks

%group SBHooks
%hook SBAssistantController
- (void)viewWillDisappear {
    //theiostream, please, remove logs like this after you are done :P
    //NSLog(@"ON VIEWDIDDISAPPEAR");
    %orig;
    
    NSLog(@"AE: Assistant dismissed.");
    SBCenterAssistantDismissed();
    
    // tell each extension the assistant is dismissed
    NSArray *ext = [AEExtension allExtensions];
    for (AEExtension* ex in ext)
        [ex callAssistantDismissed];
}
%end

%hook SBAssistantGuideModel
- (void)_loadAllDomains {
    %orig;
    
    NSMutableArray* _domains = nil;
    object_getInstanceVariable(self, "_domains", (void**)&_domains);
    if (_domains) {
        NSLog(@"AE: Populating the assistant guide.");
        
        NSArray *ext = [AEExtension allExtensions];
        for (AEExtension* ex in ext) {
            NSDictionary* pttrns = [ex patternsPlist];
            if (pttrns) {
                // create domain model
                SBAssistantGuideDomainModel* dm = [[%c(SBAssistantGuideDomainModel) alloc] init];
                if (!dm) { NSLog(@"AE: Unexpected error %s %d!!", __FILE__, __LINE__); continue; };
                [dm setBundleIdentifier:@"am.theiostre.someid"];
                [dm setName:[ex displayName]];
                
                NSString* example = [pttrns objectForKey:@"example"];
                if (example) 
                    [dm setTagPhrase:example];
                else
                    [dm setTagPhrase:[ex displayName]];
                    
                NSString* iconName = [pttrns objectForKey:@"icon"];
                if (iconName) [dm setSectionFilename:[NSString stringWithFormat:@"%@/%@", [ex name], iconName]];
                
                // create sections
                NSMutableArray* _sections = [[NSMutableArray alloc] init];
                
                NSDictionary* patternsFromPlist = [pttrns objectForKey:@"patterns"];
                for (NSString* patternKey in patternsFromPlist) {
                    NSDictionary* pat = [patternsFromPlist objectForKey:patternKey];
                    
                    NSString* cat = [pat objectForKey:@"category"];
                    if (!cat) cat = @"Uncategorized";
                    
                    NSArray* examples = [pat objectForKey:@"examples"];
                    if (!examples) continue;
                    
                    // try to find existing section by category
                    BOOL found = NO;
                    for (SBAssistantGuideSectionModel* s in _sections) {
                        if ([cat caseInsensitiveCompare:[s title]] == NSOrderedSame) {
                            [[s phrases] addObjectsFromArray:examples];
                            found = YES;
                            break;
                        }
                    }
                    
                    // not found, add
                    if (!found) {
                        SBAssistantGuideSectionModel* sec = [[%c(SBAssistantGuideSectionModel) alloc] init];
                        if (!sec) { NSLog(@"AE: Unexpected error %s %d!!", __FILE__, __LINE__); continue; };
                        [sec setTitle:cat];
                        [sec setPhrases:[NSMutableArray arrayWithArray:examples]];
                        [_sections addObject:sec];
                    }
                }
                
                if ([_sections count] > 0) {
                    // add sections to the domain model
                    object_setInstanceVariable(dm, "_sections", _sections);
                    
                    // add domain model to the list
                    [_domains addObject:dm];
                }
                
                else {
                    // just release
                    [dm release];
                }
            }
        }
    }
}
%end

%hook SBAssistantGuideDomainListController
- (SBAssistantGuideDomainListCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SBAssistantGuideDomainListCell *cell = %orig;
    
    SBAssistantGuideModel *_model = nil;
    object_getInstanceVariable(self, "_model", (void**)&_model);
    SBAssistantGuideDomainModel* dm = [[_model allDomains] objectAtIndex:indexPath.row];
    
    if (_model && dm) {
        if ([[dm bundleIdentifier] isEqualToString:@"am.theiostre.someid"]) {
            BOOL loadDefaultIcon = NO;
            
            NSArray* iconPathComponents = [[dm sectionFilename] componentsSeparatedByString:@"/"];
            if ([iconPathComponents count]<2) {
                loadDefaultIcon = YES;
                if ([[dm sectionFilename] length]>0)
                    NSLog(@"AE: Wrong icon path. Must be in format ExtensionNameWithoutPathExtension/path/inside/bundle.png");
            }
            
            else {
                NSMutableString* iconPath = [NSMutableString stringWithString:@EXTENSIONS_PATH];
                for (NSString* comp in iconPathComponents)
                    [iconPath appendFormat:@"/%@", comp];
                
                //NSLog(@"AE: Setting the icon for the guide: %@", iconPath);
                if (iconPath && [iconPath length]>0) {
                    if (![iconPath hasSuffix:@".png"] && ![iconPath hasSuffix:@".jpg"])
                        [iconPath appendString:@".png"];
                    
                    UIImage *icon = [UIImage imageWithContentsOfFile:iconPath];
                    if (!icon) {
                        NSLog(@"AE: Error loading icon for the guide from '%@'!", iconPath);
                        loadDefaultIcon = YES;
                    }
                    
                    else
                        [cell setIconImage:icon];
                }
            }
            
            // should load default icon?
            if (loadDefaultIcon) {
                UIImage* defImg = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/AEPrefs.bundle/AEPrefs@2x.png"];
                if (defImg)
                    [cell setIconImage:defImg];
                
                else
                    NSLog(@"AE: Failed to load default icon image!");
            }
        }
    }
    
    return cell;
}
%end
%end

//############### assistantd Hooks

%group ADHooks
%hook ADSession
- (void)_handleAceObject:(id)aceObj {
    s_lastSession = self;
    
    NSDictionary* dict = [aceObj dictionary];
    NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions", @"Server2Client", [NSDictionary dictionaryWithObject:dict forKey:@"object"]);
    NSDictionary* respObj = [resp objectForKey:@"object"];
    
    if (respObj) SessionSend(0, respObj);
}

- (void)sendCommand:(id)cmd {
    %log;
    s_lastSession = self;
    
    NSDictionary* dict = [cmd dictionary];
    NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions", @"Client2Server", [NSDictionary dictionaryWithObject:dict forKey:@"object"]);
    NSDictionary* respObj = [resp objectForKey:@"object"];
    
    if (respObj) SessionSend(1, respObj);
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

//############### Definitions
id AECreateAceObjectFromDictionary(NSDictionary *dict) {
	id ctx = [[[objc_getClass("BasicAceContext") alloc] init] autorelease];
    id obj = [objc_getClass("AceObject") aceObjectWithDictionary:dict context:ctx];
    
    return obj;
}

BOOL SessionSend(int type, NSDictionary *dict) {
	if (!s_lastSession) { NSLog(@"######### HALT! SESSION IS NIL!"); return NO; }
	if (!dict)			{ NSLog(@"######### HALT! DICT IS NIL!"); return NO; }
    
    id obj = AECreateAceObjectFromDictionary(dict);
    if (!obj) { NSLog(@"######### HALT! OBJ IS NIL!"); return NO; }
    
    if (type == 0)
    	_logos_orig$ADHooks$ADSession$_handleAceObject$(s_lastSession, @selector(_handleAceObject:), obj);
    else if (type == 1)
    	_logos_orig$ADHooks$ADSession$sendCommand$(s_lastSession, @selector(sendCommand:), obj);
    
    //NSLog(@"RETURNING LE YES K?");
    return YES;
}

//############### Constructor
%ctor {
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    
	NSString* bundleIdent = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"[AssistantExtensions] Loading into %@", bundleIdent);
    
    %init;
    
    if ([bundleIdent isEqualToString:@"com.apple.springboard"]) {
        %init(SBHooks);
        [[AESpringBoardMsgCenter alloc] init];
        
        AESupportInit();
    }
    
    else if ([bundleIdent isEqualToString:@"com.apple.AssistantServices"]) {   
        %init(ADHooks);
        [[AEAssistantdMsgCenter alloc] init];
    }
    
    [pool drain];
}