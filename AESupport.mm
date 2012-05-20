//
//  AESupport.mm
//  SiriCommands
//
//  Created by Kexik on 1/22/12.
//  Copyright (c) 2012 K3A. All rights reserved.
//
#include "AESupport.h"
#include "shared.h"
#include "main.h"

#import <VoiceServices.h>

bool AESendToClient(NSDictionary* aceObject) {
    if (InSpringBoard()) {
        NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions.ad", @"Send2Client", 
                                             [NSDictionary dictionaryWithObject:aceObject forKey:@"object"]);
        return [[resp objectForKey:@"reply"] boolValue];
    }
    
    return SessionSend(kSendToClient, aceObject);
}

bool AESendToServer(NSDictionary* aceObject) {
  	if (InSpringBoard()) {
        NSDictionary* resp = IPCCallResponse(@"me.k3a.AssistantExtensions.ad", @"Send2Server", 
                                             [NSDictionary dictionaryWithObject:aceObject forKey:@"object"]);
        return [[resp objectForKey:@"reply"] boolValue];
    }
    
    return SessionSend(kSendToServer, aceObject);
}

static VSSpeechSynthesizer* s_synth = nil;

void AESupportInit() {
	s_synth = [[VSSpeechSynthesizer alloc] init];
	[s_synth setVoice:@"Samantha"];
	// TODO: set correct voice based on language
}

void AESay(NSString* text, NSString* lang) {
    if (InSpringBoard())
       [s_synth startSpeakingString:text withLanguageCode:lang];
       
    else
        IPCCall(@"me.k3a.AssistantExtensions.ad", @"Say", 
                        [NSDictionary dictionaryWithObjectsAndKeys:text,@"text",lang,@"lang", nil]);
}


NSString* AEGetSystemLanguage() {
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    /*NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
     NSArray* arrayLanguages = [userDefaults objectForKey:@"AppleLanguages"];
     NSString* language = [arrayLanguages objectAtIndex:0];*/
    
    char lang[16];
    strcpy(lang, [language UTF8String]);
    
    unsigned sepIdx = strlen(lang);
    bool afterSep = false;
    for (unsigned i=0; i<strlen(lang); i++) {
        if (lang[i] == '_' || lang[i] == '-') {
            lang[i] = '-';
            sepIdx = i;
            afterSep = true;
        }
        
        else if (afterSep)
            lang[i] = toupper(lang[i]);
    }
    
    return [NSString stringWithUTF8String:lang];
}

NSString* AEGetAssistantLanguage() {
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.assistant.plist"];
    NSString* lang = [dict objectForKey:@"Session Language"];
    if ([lang length])
        return lang;
    
    return @"en-US";
}