#import "AECustomizerCommands.h"

@implementation AECustomizerCommands
-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx {
	NSArray *pref = [NSArray arrayWithContentsOfFile:@"/var/mobile/Library/Preferences/me.k3a.ae.customizer.plist"];
	if (!pref) pref = [NSArray array];
	NSMutableArray *views = [NSMutableArray array];
	
	for (NSDictionary *dict in pref) {
		NSString *get = [dict objectForKey:@"get"];
		NSString *put = [dict objectForKey:@"put"];
		if (!get || !put) continue;
		
		if ([[text lowercaseString] isEqualToString:[get lowercaseString]]) {
			[views addObject:[ctx createAssistantUtteranceView:put]];
			[ctx sendAddViewsUtteranceView:put];
			
			return YES;
		}
	}
	
	return NO;
}
@end
// vim:ft=objc
