//
//  YouTubeSnippet.m
//  YouTubeSnippet
//
//  Created by K3A on 12/18/11.
//  Copyright (c) 2011 K3A.me. All rights reserved.
//

#import "YouTubeSnippet.h"
#import "YouTubeCommands.h"
#import <Foundation/Foundation.h>

@implementation K3AYouTubeSnippet
- (id)view {
    return _view;
}

- (void)dealloc {
    [_view release];
    [_results release];
    [_query release];
    [_thumbs release];
	[super dealloc];
}

- (id)initWithProperties:(NSDictionary*)props {
    if ((self = [super init])) {
        _results = [[props objectForKey:@"results"] retain];
        _thumbs = [[props objectForKey:@"thumbs"] retain];
        _query = [[props objectForKey:@"query"] retain];
        
        _view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_view setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [_view setBackgroundColor:[UIColor clearColor]];
        [_view setDelegate:self];
        [_view setDataSource:self];
    }
    
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_results count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"YoutubeResult";
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    	cell.textLabel.textColor = [UIColor whiteColor];
    	
    	if ((unsigned int)indexPath.row < [_results count]) {
    		cell.textLabel.text = [[_results objectAtIndex:indexPath.row] objectForKey:@"title"];
			cell.imageView.image = [UIImage imageWithData:[_thumbs objectAtIndex:indexPath.row]];
		}	
		else cell.textLabel.text = @"More...";
	}
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *url = ((NSUInteger)indexPath.row < [_results count]) ?
    	[NSString stringWithFormat:@"http://youtube.com/watch?v=%@", [[_results objectAtIndex:indexPath.row] objectForKey:@"id"]] :
    	[NSString stringWithFormat:@"http://m.youtube.com/results?q=%@", [_query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
@end

// -------------------

@implementation K3AYouTube
- (id)initWithSystem:(id<SESystem>)system {
    if ((self = [super init])) {
        [system registerCommand:[K3AYouTubeCommands class]];
        [system registerSnippet:[K3AYouTubeSnippet class]];
    }
    
    return self;
}

// optional info about extension
-(NSString*)author {
    return @"K3A";
}

-(NSString*)name {
    return @"YouTube";
}

-(NSString*)description {
    return @"YouTube search";
}

-(NSString*)website {
    return @"www.k3a.me";
}
@end