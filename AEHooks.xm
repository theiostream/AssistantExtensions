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
%*/

#import "AESpringBoardMsgCenter.h"
#import "AEExtension.h"
#import "main.h"

//############### SpringBoard Hooks

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
                [dm setBundleIdentifier:@"me.k3a.ace.extension"];
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
        if ([[dm bundleIdentifier] isEqualToString:@"me.k3a.ace.extension"]) {
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

//############### assistantd Hooks

/*%hook BasicAceContext
- (id)init {
	s_regDone = YES;
	
	id orig = %orig;
	[self addAcronym:@"SAK3AExtension" forGroup:@"me.k3a.ace.extension"];
	return orig;
}
%end

%hook ADSession
- (void)_handleAceObject:(id)aceObj {
	*/