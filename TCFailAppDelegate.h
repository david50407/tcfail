//
//  TCFailAppDelegate.h
//  TCFail
//
//  Created by Weizhong Yang on 8/29/09.
//

#import <Cocoa/Cocoa.h>

extern NSString *plistPath;

@interface TCFailAppDelegate : NSObject <NSApplicationDelegate> 
{
    NSWindow *window;
	NSTableView *tableView;

	NSMutableArray *availableFontArray;
}

- (IBAction)change:(id)sender;

@property (assign, nonatomic) IBOutlet NSWindow *window;
@property (assign, nonatomic) IBOutlet NSTableView *tableView;

@end
