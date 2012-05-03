/*%%%%
%% main.h
%% Main function header for AssistantExtensions
%%*/

#include "shared.h"

#define kSendToClient 0
#define kSendToServer 1
BOOL SessionSend(int type, NSDictionary *dict);

#define EXTENSIONS_PATH "/Library/AssistantExtensions/"
#define InSpringBoard()	[[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]