/*%%%%
%% AETool.m
%% Created by theiostream on 20/5/2012
%% Fuck the world
%% It uses goto too! :P
%%%%*/

#import <AppSupport/CPDistributedMessagingCenter.h>
static void IPCCall(NSString* center, NSString* message, NSDictionary* object) {
    [[CPDistributedMessagingCenter centerNamed:center] sendMessageName:message userInfo:object];
}

static void usage() {
	fprintf(stderr, "Usage: aetool <option> [args]\n");
	fprintf(stderr, "\t-q query: Query Siri with args\n");
	fprintf(stderr, "\t-a activate: Activate the assistant\n");
	fprintf(stderr, "\t-d dismiss: Dismiss the assistant\n");
}

static void send_query(char* query) {
	NSString *qString = [NSString stringWithCString:query encoding:NSUTF8StringEncoding];
	
	IPCCall(@"me.k3a.AssistantExtensions", @"ActivateAssistant", nil);
	IPCCall(@"me.k3a.AssistantExtensions", @"SubmitQuery", [NSDictionary dictionaryWithObjectsAndKeys:qString,@"query", nil]);
}

int main(int argc, char **argv) {
	int c;
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	if (argc < 2) {
		usage();
		goto end;
	}
	
	while ((c = getopt(argc, argv, "q:ad")) != -1) {
		switch (c) {
			case 'q':
				send_query(optarg);
				break;
				
			case 'a':
				IPCCall(@"me.k3a.AssistantExtensions", @"ActivateAssistant", nil);
				break;
				
			case 'd':
				IPCCall(@"me.k3a.AssistantExtensions", @"DismissAssistant", nil);
				break;
				
			case ':':
				usage();
				break;
				
			case '?':
				usage();
				break;
		}
	}
	
	end:
		[pool drain];
		return 0;
}