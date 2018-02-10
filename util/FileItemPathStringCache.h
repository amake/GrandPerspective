#import <Cocoa/Cocoa.h>


@class FileItem;

@interface FileItemPathStringCache : NSObject {

  BOOL  addTrailingSlashToDirectoryPaths;
  NSMutableArray  *cachedPathStrings;
  NSMutableArray  *cachedFileItems;

}

@property (nonatomic) BOOL addTrailingSlashToDirectoryPaths;

- (NSString *)pathStringForFileItem:(FileItem *)item;
- (void) clearCache;

@end
