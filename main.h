#pragma once

#include "shared.h"

#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "SiriObjects.h"

/*// sends immediately without additional processing
BOOL SessionSendToClient(NSDictionary* dict, id ctx=nil);
// sends immediately without additional processing
BOOL SessionSendToServer(NSDictionary* dict, id ctx=nil);*/

#define kSendToClient 0
#define kSendToServer 1
BOOL SessionSend(int type, NSDictionary *dict);

bool RegisterAcronymImpl(NSString* acronym, NSString* group);
NSArray* GetAcronyms();

bool InSpringBoard();

#define EXTENSIONS_PATH "/Library/AssistantExtensions/"

#pragma mark - K3A's MS HELPER MACROS ------------------------------------------

#define CALL_ORIG(args...) \
return __orig_fn(self, sel, ## args)

#define ORIG(args...) \
__orig_fn(self, sel, ## args)


#define GET_CLASS(class) \
Class $ ## class = objc_getClass(#class);


#define GET_METACLASS(class) \
Class $ ## class = objc_getMetaClass(#class);


#define HOOK(className, name, type, args...) \
@class className; \
static type (*_ ## className ## $ ## name)(className *self, SEL sel, ## args) = NULL; \
static type $ ## className ## $ ## name(className *self, SEL sel, ## args) { \
type (*__orig_fn)(className *self, SEL sel, ## args) = _ ## className ## $ ## name ; __orig_fn=__orig_fn;

#define END }

#define LOAD_HOOK(class, sel, imp) \
if ($ ## class) { MSHookMessage($ ## class, @selector(sel), MSHake(class ## $ ## imp)); }
