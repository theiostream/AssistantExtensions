/*%%%%%
%% AEExtensionSnippetController.xm
%% AssistantExtensions
%%
%% Rewrite of K3AExtensionSnippetController and SAK3AExtensionSnippet without
%% the need to link to SAObjects.framework.
%%
%% I did this because I lost my copy of it and I was too lazy to dyld_decache.
%%%%%*/

#import "AEExtension.h"
#import "OS5Additions.h"
#import "SiriObjects.h"
#import "SiriObjects_private.h"

static char _viewKey;
static char _snipKey;

@interface K3AExtensionSnippetController : AFUISnippetController
- (UIView *)view;
- (void)dealloc;
- (id)initWithAceObject:(id)ace delegate:(id)dlg;
@end

@interface SAK3AExtensionSnippet : SAUISnippet
- (NSString *)encodedClassName;
- (NSString *)groupIdentifier;
@end

%subclass K3AExtensionSnippetController : AFUISnippetController
- (UIView *)view {
    return (UIView *)objc_getAssociatedObject(self, &_viewKey);
}

- (void)dealloc {
    //NSLog(@">> K3AExtensionSnippetController dealloc");
    objc_setAssociatedObject(self, &_viewKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(self, &_snipKey, nil, OBJC_ASSOCIATION_ASSIGN);
    
    %orig;
}

- (id)initWithAceObject:(id)ace delegate:(id)dlg {
    //NSLog(@">> K3AExtensionSnippetController initWithAceObject: Properties: %@", [ace properties]);
    
    if ((self = %orig)) {
        if (![ace isKindOfClass:%c(SAK3AExtensionSnippet)]) {
            NSLog(@"[AssistantExtensions] Error: Wrong class received (got %s, expected SAK3AExtensionSnippet)", object_getClassName(ace));
            [self release];
            return nil;
        }
        
        NSString* snipClass = [[ace properties] objectForKey:@"snippetClass"];
        NSDictionary* snipProps = [[ace properties] objectForKey:@"snippetProps"];
        if (!snipProps) snipProps = [NSDictionary dictionary];
        
        if (!snipClass || [snipClass isEqualToString:@""]) {
            NSLog(@"AE ERROR: Snippet class not specified!");
            [self release];
            return nil;
        }
        
        UIView *snippetView;
        NSArray *allExtensions = [AEExtension allExtensions];
        for (AEExtension* ex in allExtensions) {
            NSObject<SESnippet> *snip = [ex allocSnippet:snipClass properties:snipProps];
            if (snip) {
            	snippetView = [[snip view] retain];
            	
            	objc_setAssociatedObject(self, &_snipKey, snip, OBJC_ASSOCIATION_RETAIN);
            	goto end;
            }
        }
        
       	NSLog(@"AE ERROR: Snippet class %@ could not be found in any loaded extension bundle!", snipClass);
        [self release];
    	return nil;
        
        end:
        objc_setAssociatedObject(self, &_viewKey, snippetView, OBJC_ASSOCIATION_RETAIN);
    }
    
    return self;
}
%end

%subclass SAK3AExtensionSnippet : SAUISnippet
- (id)encodedClassName {
    return @"Snippet";
}

- (id)groupIdentifier {
    return @"me.k3a.ace.extension";
}
%end