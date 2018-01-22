#import <Cocoa/Cocoa.h>

#import "FileItem.h"

extern NSString  *LogicalFileSize;
extern NSString  *PhysicalFileSize;


@class FilteredTreeGuide;
@class TreeBalancer;
@class UniformTypeInventory;
@class FileItem;
@class FilterSet;
@class DirectoryItem;
@class TreeContext;
@class ScanProgressTracker;


/* Constructs trees for folders by (recursively) scanning the folder's contents.
 */
@interface TreeBuilder : NSObject {
  FilterSet  *filterSet;

  NSString  *fileSizeMeasure;
  NSURLResourceKey  fileSizeMeasureKey;
  
  BOOL  abort;
  FilteredTreeGuide  *treeGuide;
  TreeBalancer  *treeBalancer;
  UniformTypeInventory  *typeInventory;
  
  // Contains the file numbers of the hard linked files that have been encountered so far. If a file
  // with a same number is encountered once more, it is ignored.
  NSMutableSet  *hardLinkedFileNumbers;
  
  ScanProgressTracker  *progressTracker;
  
  NSMutableArray  *dirStack;
  // The index of the top element on the stack. It is not necessarly the last object in the array,
  // as items on the stack are never popped but kept for re-use.
  int  dirStackTopIndex;
  
  BOOL  debugLogEnabled;
}

+ (NSArray *)fileSizeMeasureNames;

- (id) init;
- (id) initWithFilterSet:(FilterSet *)filterSet;

- (BOOL) packagesAsFiles;
- (void) setPackagesAsFiles:(BOOL)flag;

- (NSString *)fileSizeMeasure;
- (void) setFileSizeMeasure:(NSString *)measure;

/* Construct the tree for the given folder.
 */
- (TreeContext *)buildTreeForPath:(NSString *)path;

- (void) abort;

/* Returns a dictionary containing information about the progress of the ongoing tree-building task.
 *
 * It can safely be invoked from a different thread than the one that invoked -buildTreeForPath:
 * (and not doing so would actually be quite silly).
 */
- (NSDictionary *)progressInfo;

@end
