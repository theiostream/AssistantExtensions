#include <substrate.h>
void *MSFindSymbol(const void* image, const char *name);

static NSArray* (*original_AFPreferencesSupportedLanguages)();
static NSArray* replaced_AFPreferencesSupportedLanguages() {
    NSArray* orig = original_AFPreferencesSupportedLanguages();
    NSMutableArray* repl = [NSMutableArray arrayWithArray:orig];
    [repl addObject:@"ja-JP"];

    return repl;
}


__attribute__((constructor)) static void AEJPInit()
{
    MSHookFunction(MSFindSymbol("/System/Library/PrivateFrameworks/AssistantServices.framework/AssistantServices", "_AFPreferencesSupportedLanguages"), (void *)replaced_AFPreferencesSupportedLanguages, (void **)&original_AFPreferencesSupportedLanguages);
}
