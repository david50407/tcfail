//
//  TCFailAppDelegate.m
//  TCFail
//
//  Created by Weizhong Yang on 8/29/09.
//

#import "TCFailAppDelegate.h"
#import <Security/Security.h>

static AuthorizationRef authorizationRef = NULL;

NSString *plistPath = @"/System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreText.framework/Resources/DefaultFontFallbacks.plist";

@implementation TCFailAppDelegate

- (void)dealloc
{
	self.window = nil;
	self.tableView = nil;
	[availableFontArray release];
	[super dealloc];
}
- (void)addFontWithName:(NSString *)name
{
	NSMutableDictionary *fontDictionary = [NSMutableDictionary dictionary];
	[fontDictionary setValue:[NSNumber numberWithBool:NO] forKey:@"checked"];
	[fontDictionary setValue:name forKey:@"name"];
	[availableFontArray addObject:fontDictionary];
}
- (void)awakeFromNib
{
	[self.window center];
}
- (NSString *)tempFilePath
{
	return @"/tmp/DefaultFontFallbacks.plist";
}

- (void)logout
{
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\" to log out"];
	[script autorelease];
	[script executeAndReturnError:nil];	
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
	
	NSData *data = [NSData dataWithContentsOfFile:plistPath];
	NSPropertyListFormat format;
	id plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:NULL];
	NSArray *keys = [plist allKeys];
	for (NSString *key in keys) {
		if (!([key isEqualToString:@"sans-serif"] || [key isEqualToString:@"monospace"] || [key isEqualToString:@"default"]) ){
			continue;
		}
		
		NSArray *settings = [plist valueForKey:key];
		for (id item in settings) {
			if ([item isKindOfClass:[NSArray class]]) {
				for (NSArray *a in item) {
					if ([a count] && [[a objectAtIndex:0] isEqualToString:@"zh-Hant"]) {
						[(NSMutableArray *)a replaceObjectAtIndex:1 withObject:currentTraditionalChineseFontName];
					}
				}
			}
		}
	}
	data = [NSPropertyListSerialization dataFromPropertyList:plist format:format errorDescription:NULL];
	[data writeToFile:[self tempFilePath] atomically:YES];

	char * args[2];
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

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	
	[self.tableView setRowHeight:25.0];
	[self tempFilePath];
	
	availableFontArray = [[NSMutableArray alloc] init];
	[self addFontWithName:@"LiGothicMed"];
	[self addFontWithName:@"LiHeiPro"];
	[self addFontWithName:@"STHeitiTC-Medium"];
	[self addFontWithName:@"STHeitiTC-Light"];
	[self addFontWithName:@"STXihei"];
	[self addFontWithName:@"STHeiti"];
	[self addFontWithName:@"HiraKakuPro-W3"];
	[self addFontWithName:@"HiraKakuPro-W6"];
	[self addFontWithName:@"HiraKakuProN-W3"];
	[self addFontWithName:@"HiraKakuProN-W6"];
	[self.tableView reloadData];
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
	else if ([identifier isEqualToString:@"sample"]) {
		return @"中文字體範例 晴睛餉令零翱翔賣讀直值";
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
		[aTableView reloadData];
	}	
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *fontName = [[availableFontArray objectAtIndex:rowIndex] valueForKey:@"name"];
	NSFont *font = [NSFont fontWithName:fontName size:20.0];
	[aCell setFont:font];
}
- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:self];
}


@synthesize window;
@synthesize tableView;

@end
