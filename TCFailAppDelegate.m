//
// TCFailAppDelegate.m
// TCFail
//
// Copyright (c) Weizhong Yang (http://zonble.net)
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of TCFail nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "TCFailAppDelegate.h"
#import <Security/Security.h>

static AuthorizationRef authorizationRef = NULL;

NSString *plistPath = @"/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreText.framework/Resources/DefaultFontFallbacks.plist";

NSString *plistFolderPath = @"/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreText.framework/Resources";

@implementation TCFailAppDelegate

- (void)dealloc
{
	self.window = nil;
	self.tableView = nil;
	self.currentSystemFontName = nil;
	self.currentSelectedFontName = nil;
	[availableFontArray release];
	[super dealloc];
}
- (void)addFontWithName:(NSString *)name note:(NSString *)note
{
	NSMutableDictionary *fontDictionary = [NSMutableDictionary dictionary];
	
	if (![self.currentSystemFontName length]) {
		[fontDictionary setValue:[NSNumber numberWithBool:NO] forKey:@"checked"];
	}
	else {
		[fontDictionary setValue:[NSNumber numberWithBool:[name isEqualToString:self.currentSystemFontName]] forKey:@"checked"];
	}
	
	[fontDictionary setValue:name forKey:@"name"];
	[fontDictionary setValue:note forKey:@"note"];
	[availableFontArray addObject:fontDictionary];
}

- (void)awakeFromNib
{
	[self.window center];
}

- (NSString *)tempFilePath
{
	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/tmp" isDirectory:&isDir]) {
		if (![[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp" withIntermediateDirectories:NO attributes:nil error:nil]) {
			return nil;
		}
	}
	if (!isDir) {
		if (![[NSFileManager defaultManager] removeItemAtPath:@"/tmp" error:nil]) {
			return nil;
		}
		if (![[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp" withIntermediateDirectories:NO attributes:nil error:nil]) {
			return nil;
		}
	}
	
	return @"/tmp/DefaultFontFallbacks.plist";
}

- (void)logout
{
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\" to log out"];
	[script autorelease];
	[script executeAndReturnError:nil];	
}

- (IBAction)agreeAction:(id)sender
{
	[NSApp endSheet:agreeWindow];
	[agreeWindow orderOut:self];
}
- (IBAction)cancelAction:(id)sender
{
	[NSApp endSheet:agreeWindow];
	[agreeWindow orderOut:self];
	[NSApp terminate:sender];
}
- (IBAction)change:(id)sender
{
	OSStatus status;
	
	if (authorizationRef == NULL) {
		status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
	}
	else {
		status = noErr;
	}
	
	if (status != noErr) {
		NSLog(@"Could not get authorization, failing.");
		NSRunAlertPanel(NSLocalizedString(@"Could not get authorization, failing.",@""), @"", NSLocalizedString(@"OK", @""), nil, nil);

		return;
	}
	
	NSString *currentTraditionalChineseFontName = nil;
	for (NSDictionary *d in availableFontArray) {
		BOOL checked = [[d valueForKey:@"checked"] boolValue];
		if (checked) {
			currentTraditionalChineseFontName = [d valueForKey:@"name"];
			break;
		}
	}
	
	if (!currentTraditionalChineseFontName) {
		NSRunAlertPanel(NSLocalizedString(@"Please select the font that you want to use.",@""), @"", NSLocalizedString(@"OK", @""), nil, nil);
		return;
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
		NSRunAlertPanel(NSLocalizedString(@"The original coretext setting does not exist! Your system might have a big problem...", @""), @"", NSLocalizedString(@"OK", @""), nil, nil);
		return;
	}
	
	NSData *data = [NSData dataWithContentsOfFile:plistPath];
	NSPropertyListFormat format;
	id plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:NULL];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
		NSRunAlertPanel(NSLocalizedString(@"Failed to parse the coretext setting! Your system might have a big problem...", @""), @"", NSLocalizedString(@"OK", @""), nil, nil);
		return;
	}
	
	NSArray *keys = [plist allKeys];
	for (NSString *key in keys) {
		if (!([key isEqualToString:@"sans-serif"] || [key isEqualToString:@"monospace"] || [key isEqualToString:@"default"]) ){
			continue;
		}
		
		NSArray *settings = [plist valueForKey:key];
		for (id item in settings) {
			if ([item isKindOfClass:[NSArray class]]) {
				for (NSArray *a in item) {
					if ([a count] && [[a objectAtIndex:0] isEqualToString:@"zh-Hans"]) {
						[(NSMutableArray *)a replaceObjectAtIndex:1 withObject:currentTraditionalChineseFontName];
					}
				}
			}
		}
	}
	data = [NSPropertyListSerialization dataFromPropertyList:plist format:format errorDescription:NULL];
	NSString *tempFilePath = [self tempFilePath];
	if (!tempFilePath) {
		NSRunAlertPanel(NSLocalizedString(@"Unable to write your setting.", @""), @"", NSLocalizedString(@"OK", @""), nil, nil);
		return;

	}
	if (![data writeToFile:[self tempFilePath] atomically:YES]) {
		NSRunAlertPanel(NSLocalizedString(@"Unable to write your setting.", @""), @"", NSLocalizedString(@"OK", @""), nil, nil);
		return;
	}

	char * args[3];
	args[0] = (char *)[[self tempFilePath] UTF8String];
	args[1] = (char *)[plistPath UTF8String];
	args[2] = (char *)NULL;
	
	status = AuthorizationExecuteWithPrivileges(authorizationRef, "/bin/cp", 0, args, NULL);
	
	if (status != noErr) {
		NSRunAlertPanel(NSLocalizedString(@"Unable to write your setting.", @""), @"", NSLocalizedString(@"OK", @""), nil, nil);
		return;
	}
	
	NSInteger result = NSRunAlertPanel(NSLocalizedString(@"The new font will take effect after logging out. Do you want to logout now?", @""), @"", NSLocalizedString(@"Logout", @""), NSLocalizedString(@"Cancel", @""), nil);
	
	if (result == NSOKButton) {
		[self logout];
	}
}
- (IBAction)openPlistFolder:(id)sender
{
	NSString *source = [NSString stringWithFormat:@"tell application \"Finder\"\nopen POSIX file \"%@\"\nactivate\nend tell", plistFolderPath];
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
	[script autorelease];
	[script executeAndReturnError:nil];		
}
- (IBAction)backupPlist:(id)sender
{
	NSString *source = [NSString stringWithFormat:@"tell application \"Finder\"\nset d to path to desktop folder\nduplicate POSIX file \"%@\" to d with replacing\nend tell", plistPath];
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
	[script autorelease];
	[script executeAndReturnError:nil];		
	
}
- (IBAction)changePreviewFontSize:(id)sender
{
	[self updatePreview];
}
- (IBAction)openHomepage:(id)sender
{
	NSURL *URL = [NSURL URLWithString:@"http://zonble.github.com/tcfail/"];
	[[NSWorkspace sharedWorkspace] openURL:URL];
}

- (void)retrieveCurrentSystemFontName
{
	NSData *data = [NSData dataWithContentsOfFile:plistPath];
	NSPropertyListFormat format;
	id plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:NULL];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
		NSRunAlertPanel(NSLocalizedString(@"Failed to parse the coretext setting! Your system might have a big problem...", @""), @"", NSLocalizedString(@"OK", @""), nil, nil);
		return;
	}
	
	NSArray *keys = [plist allKeys];
	for (NSString *key in keys) {
		if (!([key isEqualToString:@"default"])){
			continue;
		}
		
		NSArray *settings = [plist valueForKey:key];
		for (id item in settings) {
			if ([item isKindOfClass:[NSArray class]]) {
				for (NSArray *a in item) {
					if ([a count] >= 2 && [[a objectAtIndex:0] isEqualToString:@"zh-Hans"]) {
						self.currentSystemFontName = [a objectAtIndex:1];
						[self updatePreview];
						return;
					}
				}
			}
		}
	}
	self.currentSystemFontName = nil;	
}
- (void)updatePreview
{
	CGFloat fontSize = [fontSizeSlider doubleValue];
	NSString *previewText = [NSString stringWithUTF8String:"中文字體範例請晴睛餉飯食令零翱翔賣讀直值楊揚，鄉響、饗俞。輸妳好\n1234567890abcdABCD"];
	if (self.currentSystemFontName) {
		[currentSystemFontNameLabel setStringValue:NSLocalizedString(self.currentSystemFontName, @"")];
		NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:self.currentSystemFontName size:fontSize], NSFontAttributeName, nil];
		NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:previewText attributes:attr] autorelease];
		[[currrentSystemFontPreviewTextView textStorage] setAttributedString:attrString];
	}
	else {
		[currentSystemFontNameLabel setStringValue:NSLocalizedString(@"None", @"")];
		[[[currrentSystemFontPreviewTextView textStorage] mutableString] setString:@""];
	}
	if (self.currentSelectedFontName) {
		[currentSelectedFontNameLabel setStringValue:NSLocalizedString(self.currentSelectedFontName, @"")];
		NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:self.currentSelectedFontName size:fontSize], NSFontAttributeName, nil];
		NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:previewText attributes:attr] autorelease];
		[[currentSelectedFontPreviewTextView textStorage] setAttributedString:attrString];
		
	}
	else {
		[currentSelectedFontNameLabel setStringValue:NSLocalizedString(@"None", @"")];
		[[[currentSelectedFontPreviewTextView textStorage] mutableString] setString:@""];
	}
	
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	[self.tableView setRowHeight:25.0];
	[self retrieveCurrentSystemFontName];
	
	NSLog(@"current system font name: %@", self.currentSystemFontName);
	
	availableFontArray = [[NSMutableArray alloc] init];
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSArray *fonts = [fontManager availableFonts];
    for (NSString *font in fonts)
    {
        [self addFontWithName:font note:font];
    }
    
    /*
	[self addFontWithName:@"LiHeiPro" note:@"Default TC font of Mac OS X 10.5"];
	[self addFontWithName:@"LiGothicMed" note:@"Traditional Chinese font"];
	[self addFontWithName:@"STXihei" note:@"Simplified Chinese font"];
	[self addFontWithName:@"STHeiti" note:@"Simplified Chinese font"];
	[self addFontWithName:@"HiraginoSansGB-W3" note:@"Japanese font with Chinese codepoint coverage"];
	[self addFontWithName:@"HiraginoSansGB-W6" note:@"Japanese font with Chinese codepoint coverage"];
	[self addFontWithName:@"HiraKakuPro-W3" note:@"Japanese font"];
	[self addFontWithName:@"HiraKakuPro-W6" note:@"Japanese font"];
	[self addFontWithName:@"HiraKakuProN-W3" note:@"Japanese font"];
	[self addFontWithName:@"HiraKakuProN-W6" note:@"Japanese font"];
	[self addFontWithName:@"STHeitiTC-Medium" note:@"Default TC font of Mac OS X 10.6"];
	[self addFontWithName:@"STHeitiTC-Light" note:@"Default TC font of Mac OS X 10.6"];
    [self addFontWithName:@"Lantinghei" note:@""];
     */
    
	[self.tableView reloadData];

	NSUInteger selectedRow;
	for (selectedRow = 0 ; selectedRow < [availableFontArray count] ; selectedRow++) {
		if ([[[availableFontArray objectAtIndex:selectedRow] valueForKey:@"checked"] boolValue]) {
			break;
		}
	}
	
	if (selectedRow < [availableFontArray count]) {
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	}
	
	[agreeWindow setDefaultButtonCell:[agreeButton cell]];
	[NSApp beginSheet:agreeWindow modalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [availableFontArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSDictionary *d = [availableFontArray objectAtIndex:rowIndex];
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqualToString:@"use"]) {
		return [d valueForKey:@"checked"];
	}
	else if ([identifier isEqualToString:@"name"]) {
		return NSLocalizedString([d valueForKey:@"name"], @"");
	}
	else if ([identifier isEqualToString:@"note"]) {
		return NSLocalizedString([d valueForKey:@"note"], @"");
	}
	return nil;
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSMutableDictionary *d = [availableFontArray objectAtIndex:rowIndex];
	NSString *identifier = [aTableColumn identifier];

	if ([identifier isEqualToString:@"use"]) {
		for (NSMutableDictionary *dict in availableFontArray) {
			[dict setValue:[NSNumber numberWithBool:NO] forKey:@"checked"];
		}
		
		[d setValue:[NSNumber numberWithBool:YES] forKey:@"checked"];
		self.currentSelectedFontName = [d valueForKey:@"name"];
		[self updatePreview];
	}	
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqualToString:@"name"]) {
		NSString *fontName = [[availableFontArray objectAtIndex:rowIndex] valueForKey:@"name"];
		NSFont *font = [NSFont fontWithName:fontName size:[NSFont systemFontSize]];
		[aCell setFont:font];
	}
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	for (NSMutableDictionary *dict in availableFontArray) {
		[dict setValue:[NSNumber numberWithBool:NO] forKey:@"checked"];
	}	
	
	NSTableView *theTableView = [aNotification object];
	NSInteger selectedRow = [theTableView selectedRow];
	NSMutableDictionary *d = [availableFontArray objectAtIndex:selectedRow];
	[d setValue:[NSNumber numberWithBool:YES] forKey:@"checked"];
	self.currentSelectedFontName = [d valueForKey:@"name"];	
	[self updatePreview];
	[theTableView reloadData];

}

#pragma mark NSWindow

- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:self];
}


@synthesize window;
@synthesize tableView;
@synthesize currentSystemFontName;
@synthesize currentSelectedFontName;

@end
