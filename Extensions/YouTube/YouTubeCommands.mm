//
//  YouTubeCommands.mm
//  YouTube
//
//  Created by K3A on 12/29/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

// TODO: check if _views leaks.

#import "YouTubeCommands.h"

@implementation K3AYouTubeCommands
-(void)processRequest:(NSString*)q {
    if (!_ctx) { return; } // failed
    
    // create request url
    NSString* strURL = [NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos?q=%@&orderby=relevance&start-index=1&max-results=7&v=2&format=1&alt=jsonc", [q stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:strURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSError* err=nil;
    NSDictionary* obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    NSArray* arrEntries = [[obj objectForKey:@"data"] objectForKey:@"items"];
    if (err || !obj || !arrEntries) {
        [_ctx sendAddViewsUtteranceView:@"Sorry, an unexpected response returned."];
        [_ctx sendRequestCompleted];
        _ctx = nil;
        return;
    }
    
    NSLog(@"Found %u YouTube results...", [arrEntries count]);
    if ([arrEntries count] == 0) {
        [_ctx sendAddViewsUtteranceView:@"Nothing has been found."];
        [_ctx sendRequestCompleted];
        _ctx = nil;
        return;
    }
    
    NSMutableArray *arrThumbs = [NSMutableArray arrayWithCapacity:[arrEntries count]];
    
    //unsigned idx=0;
    for (NSDictionary* item in arrEntries) {
        NSString* thumbUrlStr = [[item objectForKey:@"thumbnail"] objectForKey:@"sqDefault"];
        NSURL* thumbUrl = [NSURL URLWithString:thumbUrlStr];
        NSURLRequest *thumbRequest = [NSURLRequest requestWithURL:thumbUrl];
        
        NSData *thumbData = [NSURLConnection sendSynchronousRequest:thumbRequest returningResponse:nil error:nil];
        [arrThumbs addObject:(thumbData ? thumbData : [NSData data])];
    }
    
    // create and send snippet 
    NSDictionary* snipProps = [NSDictionary dictionaryWithObjectsAndKeys:arrEntries,@"results",q,@"query",arrThumbs,@"thumbs", nil];
    [_ctx sendAddViewsSnippet:@"K3AYouTubeSnippet" properties:snipProps];
    [_ctx sendRequestCompleted];
    
    _ctx = nil;
}

-(BOOL)handleSpeech:(NSString*)text tokens:(NSArray*)tokens tokenSet:(NSSet*)tokenset context:(id<SEContext>)ctx
{
    if (_ctx) { NSLog(@"[AE] YouTube: returning NO"); return NO; } // already preocessing
    
    // reacts to only one token - "test" 
	if ([tokenset containsObject:@"youtube"] || ([tokenset containsObject:@"you"] && [tokenset containsObject:@"tube"]))
	{
        _ctx = ctx;
        
        NSMutableString* q = [NSMutableString string];
        for (NSUInteger num = 0; num < [tokens count]; num++)
        {
            NSString* str = [tokens objectAtIndex:num];
            
            if ([str isEqualToString:@"youtube"]) // skip youtube
                continue;
            else if (num+2 == [tokens count] && [str isEqualToString:@"on"]) // skip on youtube
                continue;
            else if (num == 0 && ([str isEqualToString:@"search"] || [str isEqualToString:@"find"])) // skip search/find
                continue;
            else if (num == 0 && num+1 < [tokens count] && [str isEqualToString:@"look"] && [[tokens objectAtIndex:num+1] isEqualToString:@"up"]) // skip look up
            {
                num++;
                continue;
            }
            else
                [q appendFormat:@"%@ ", str];
        }
		
		NSLog(@"Youtube query: '%@'", q);
		
        // reflection...
        NSString* str = @"Searching YouTube for you...";
        [ctx sendAddViewsUtteranceView:str speakableText:str dialogPhase:@"Reflection" scrollToTop:NO temporary:NO];
        
        [self performSelectorInBackground:@selector(processRequest:) withObject:q];
		return YES;
	}
	
	NSLog(@"[AE] YouTube: returning NO");
	return NO;	
}
@end