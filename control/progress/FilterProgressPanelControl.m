#import "FilterProgressPanelControl.h"

#import "FilterTaskExecutor.h"
#import "FilterTaskInput.h"
#import "TreeContext.h"
#import "DirectoryItem.h"


@implementation FilterProgressPanelControl

- (NSString *)windowTitle {
  return NSLocalizedString(@"Filtering in progress", @"Title of progress panel.");
}

- (NSString *)progressDetailsFormat {
  return NSLocalizedString(@"Filtering %@", @"Message in progress panel while filtering");
}

- (NSString *)progressSummaryFormat {
  return NSLocalizedString(@"%d folders filtered", @"Message in progress panel while filtering");
}

- (NSString *)pathFromTaskInput:(id)taskInput {
  return ((FilterTaskInput *)taskInput).treeContext.scanTree.path;
}

- (NSDictionary *)progressInfo {
  return  ((FilterTaskExecutor *)taskExecutor).progressInfo;
}

@end
