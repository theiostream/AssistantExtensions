/*
 *  shared.h
 *  AssistantExtensions
 *
 *  Created by K3A on 13.3.11.
 *  Copyright 2011 K3A. All rights reserved.
 *
 */

NSString* RandomUUID();

void IPCCall(NSString* center, NSString* message, NSDictionary* object);
NSDictionary* IPCCallResponse(NSString* center, NSString* message, NSDictionary* object);