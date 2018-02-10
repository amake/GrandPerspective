#import <Cocoa/Cocoa.h>
#import "Compatibility.h"

@class DirectoryView;

@interface ColorLegendTableViewControl : NSObject <NSTableViewDataSource> {

  DirectoryView  *dirView;
  NSTableView  *tableView;
  NSMutableArray  *colorImages;

}

- (instancetype) initWithDirectoryView:(DirectoryView *)dirView
                             tableView:(NSTableView *)tableView NS_DESIGNATED_INITIALIZER;

@end
