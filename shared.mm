/*
 *  shared.mm
 *  AssitantExtensions
 *
 *  Created by K3A on 13.3.11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "shared.h"
#include <time.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

#pragma mark - OTHER HELPERS -----------------------------------------------------------

NSString* RandomUUID() {
    CFUUIDRef u = CFUUIDCreate(NULL);
    return (NSString *)CFUUIDCreateString(NULL, u);
}

void IPCCall(NSString* center, NSString* message, NSDictionary* object) {
    [[CPDistributedMessagingCenter centerNamed:center] sendMessageName:message userInfo:object];
}

NSDictionary* IPCCallResponse(NSString* center, NSString* message, NSDictionary* object) {
    return [[CPDistributedMessagingCenter centerNamed:center] sendMessageAndReceiveReplyName:message userInfo:object];
}