#include <substrate.h>

static NSArray* (*original_AFPreferencesSupportedLanguages)();

static NSArray* replaced_AFPreferencesSupportedLanguages() {
    NSArray* orig = original_AFPreferencesSupportedLanguages();
    NSMutableArray* repl = [NSMutableArray arrayWithArray:orig];
    [repl addObject:@"ja-JP"];

    return repl;
}

__attribute__((constructor)) void AEJPSupportInit() {
    // FIXME: Should I not pass NULL as first argument of MSFindSymbol?
    MSHookFunction((NSArray*(*)())MSFindSymbol(NULL, "_AFPreferencesSupportedLanguages"), replaced_AFPreferencesSupportedLanguages, &original_AFPreferencesSupportedLanguages);
}