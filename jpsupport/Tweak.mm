#include <substrate.h>
#import <Foundation/Foundation.h>

static NSArray *(*original_AFPreferencesSupportedLanguages)();

static NSArray *replaced_AFPreferencesSupportedLanguages() {
    NSArray *orig = original_AFPreferencesSupportedLanguages();
    NSMutableArray *repl = [NSMutableArray arrayWithArray:orig];
    
    // This check is not necessary since we only load at 5.0-5.1.
    // But precaution anyway.
    if (![repl containsObject:@"ja-JP"]) {
		[repl addObject:@"ja-JP"];
	}

    return repl;
}

__attribute__((constructor))
static void AEJPSupportInit() {
	NSLog(@"[AssistantExtensions] JPSupport: Loading.");
	
    // FIXME: Should I not pass NULL as first argument of MSFindSymbol?
    MSHookFunction((NSArray*(*)())MSFindSymbol(NULL, "_AFPreferencesSupportedLanguages"), replaced_AFPreferencesSupportedLanguages, &original_AFPreferencesSupportedLanguages);
}