//
//  AppDelegate.m
//  MenuBarSwitcher
//
//  Created by gltchitm on 5/5/21.
//

#import "AppDelegate.h"
#import <signal.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@property (strong) NSURL *originalDesktopImage;

@end

@implementation AppDelegate

NSURL *desktopImageLocked;
NSURL *desktopImageUnlocked;

void hangup_handler(int signal) {
    reloadDesktopImagePaths();
}
void reloadDesktopImagePaths(void) {
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSURL *currentDesktopImage = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:mainScreen];
    
    if ([[NSUserDefaults standardUserDefaults] URLForKey:@"DesktopImageLocked"] == nil) {
        [[NSUserDefaults standardUserDefaults] setURL:currentDesktopImage
                                               forKey:@"DesktopImageLocked"];
        [[NSUserDefaults standardUserDefaults] setURL:currentDesktopImage
                                               forKey:@"DesktopImageUnlocked"];
        desktopImageLocked = currentDesktopImage;
        desktopImageUnlocked = currentDesktopImage;
    } else {
        desktopImageLocked = [[NSUserDefaults standardUserDefaults] URLForKey:@"DesktopImageLocked"];
        desktopImageUnlocked = [[NSUserDefaults standardUserDefaults] URLForKey:@"DesktopImageUnlocked"];
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    reloadDesktopImagePaths();
    
    NSScreen *mainScreen = [NSScreen mainScreen];
    self.originalDesktopImage = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:mainScreen];

    [self setDesktopImageURL:desktopImageUnlocked];
    
    [self.window setLevel:NSFloatingWindowLevel];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(screenIsLocked)
                                                            name:@"com.apple.screenIsLocked"
                                                          object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(screenIsUnlocked)
                                                            name:@"com.apple.screenIsUnlocked"
                                                          object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    
    signal(SIGHUP, hangup_handler);
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([NSApp isActive]) {
        [self runAlertWithMessageText:@"Quit MenuBarSwitcher"
                  withInformativeText:@"You must quit MenuBarSwitcher with the close button."
                     withButtonTitles:@[@"OK"]];
        return NSTerminateCancel;
    } else {
        return NSTerminateNow;
    }
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self setDesktopImageURL:self.originalDesktopImage];
}

- (NSModalResponse)runAlertWithMessageText:(NSString *)messageText
                       withInformativeText:(NSString *)informativeText
                          withButtonTitles:(NSArray *)buttonTitles {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = messageText;
    alert.informativeText = informativeText;
    alert.alertStyle = NSAlertStyleInformational;
    for (NSString *title in buttonTitles) {
        [alert addButtonWithTitle:title];
    }
    
    return [alert runModal];
}
- (NSURL *)runFileDialogWithDirectoryURL:(NSURL *)directoryURL {
    NSOpenPanel *fileDialog = [NSOpenPanel openPanel];
    [fileDialog setCanChooseFiles:TRUE];
    [fileDialog setCanChooseDirectories:FALSE];
    [fileDialog setAllowsOtherFileTypes:FALSE];
    [fileDialog setDirectoryURL:directoryURL];
    [fileDialog setAllowedContentTypes:@[
        [UTType typeWithFilenameExtension:@"png"],
        [UTType typeWithFilenameExtension:@"jpg"],
        [UTType typeWithFilenameExtension:@"heif"],
        [UTType typeWithFilenameExtension:@"heic"]
    ]];
    
    if ([fileDialog runModal] != NSModalResponseOK) {
        return nil;
    }
    return [fileDialog URLs][0];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    if (![NSApp isActive] || aNotification.object != self.window) {
        return;
    }
    
    NSString *hideOrExitInformativeText = @"Do you want to hide MenuBarSwitcher "
        @"(close this configuration window but continue operating) or exit it "
        @"(close this configuration window and stop operation completely)?\n\n"
        @"All changes are already saved.";
    NSModalResponse hideOrExit = [self runAlertWithMessageText:@"Hide or Exit?"
                                           withInformativeText:hideOrExitInformativeText
                                              withButtonTitles:@[@"Hide", @"Exit"]];
    
    if (hideOrExit == NSAlertFirstButtonReturn) {
        NSString *hideMenuBarSwitcherReopenMenuWarningText = @"You must kill MenuBarSwitcher "
            @"through Activity Monitor and reopen it to regain access to this menu.\n\n"
            @"NOTE: You can also send SIGHUP to MenuBarSwitcher if you want to reload "
            @"background image paths without restarting the process. Doing this will NOT "
            @"reopen this menu. This will also not change the current background photo.";
        [self runAlertWithMessageText:@"Hide MenuBarSwitcher"
                  withInformativeText:hideMenuBarSwitcherReopenMenuWarningText
                     withButtonTitles:@[@"OK"]];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    } else {
        [self setDesktopImageURL:self.originalDesktopImage];
        exit(0);
    }
}

- (NSError*)setDesktopImageURL:(NSURL*)url {
    NSError *error;
    [[NSWorkspace sharedWorkspace] setDesktopImageURL:url
                                            forScreen:[NSScreen mainScreen]
                                              options:@{}
                                                error:&error];
    
    return error;
}

- (void)screenIsLocked {
    [self setDesktopImageURL:desktopImageLocked];
}
- (void)screenIsUnlocked {
    [self setDesktopImageURL:desktopImageUnlocked];
}

- (IBAction)unlockedImageSelect:(NSButton *)sender {
    NSURL *url = [self runFileDialogWithDirectoryURL:desktopImageUnlocked];
    
    if (url != nil) {
        desktopImageUnlocked = url;
        [[NSUserDefaults standardUserDefaults] setURL:url
                                               forKey:@"DesktopImageUnlocked"];
        [self screenIsUnlocked];
        [self runAlertWithMessageText:@"Unlocked Image"
                  withInformativeText:@"Sucessfully updated the unlocked image."
                     withButtonTitles:@[@"OK"]];
    }
}
- (IBAction)lockedImageSelect:(NSButton *)sender {
    NSURL *url = [self runFileDialogWithDirectoryURL:desktopImageLocked];
    
    if (url != nil) {
        desktopImageLocked = url;
        [[NSUserDefaults standardUserDefaults] setURL:url
                                               forKey:@"DesktopImageLocked"];
        [self runAlertWithMessageText:@"Locked Image"
                  withInformativeText:@"Sucessfully updated the locked image."
                     withButtonTitles:@[@"OK"]];
    }
}

@end
