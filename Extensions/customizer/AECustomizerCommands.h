#import "SiriObjects.h"

@interface AECustomizerCommands : NSObject<SECommand> {
	id<SEContext> _ctx;
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx;

@end
// vim:ft=objc
