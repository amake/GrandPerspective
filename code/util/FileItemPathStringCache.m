 #import "FileItemPathStringCache.h"

#import "DirectoryItem.h"

@interface FileItemPathStringCache (PrivateMethods)

- (NSString *)finishDirectoryPath: (NSString *)path 
                pathComponent: (NSString *)comp;

- (void) fillCacheToItem: (FileItem *)item;

@end


@implementation FileItemPathStringCache

- (id) init {
  if (self = [super init]) {
    addTrailingSlashToDirectoryPaths = NO;
    
    cachedPathStrings = [[NSMutableArray alloc] initWithCapacity: 8];
    cachedFileItems = [[NSMutableArray alloc] initWithCapacity: 8];
  }
  
  return self;
}

- (void) dealloc {
  [cachedPathStrings release];
  [cachedFileItems release];
  
  [super dealloc];
}


- (BOOL) addTrailingSlashToDirectoryPaths {
  return addTrailingSlashToDirectoryPaths;
}

- (void) setAddTrailingSlashToDirectoryPaths: (BOOL)flag {
  addTrailingSlashToDirectoryPaths = flag;
}


- (NSString*) pathStringForFileItem: (FileItem *)item {
  DirectoryItem  *parentDirectory = [item parentDirectory];

  while ([cachedFileItems count]) {
    DirectoryItem  *lastFileItem = [cachedFileItems lastObject];
    
    if (lastFileItem == item) {
      // Found it
      return [cachedPathStrings lastObject];
    }
    if (lastFileItem == parentDirectory) {
      break;
    }
    
    [cachedPathStrings removeLastObject];
    [cachedFileItems removeLastObject];
  }

  NSString  *pathString;
  NSString  *comp = [item pathComponent];
  
  if (parentDirectory == nil) {
    pathString = (comp != nil) ? comp : @"";
  }
  else {
    if ([cachedFileItems count] == 0) {
      // Exhausted the cache. Fill it recursively all the way from the root.
      // This way, the condition "lastFileItem==nil" signals that the array
      // is empty.
      [self fillCacheToItem: parentDirectory];
    }

    // Cache is currently filled to parent directory. Use it to construct
    // new path.
    pathString = ( (comp != nil) ? [[cachedPathStrings lastObject] 
                                       stringByAppendingPathComponent: comp] 
                                 : [cachedPathStrings lastObject] );
  }
  
  if ( [item isDirectory] ) {
    pathString = [self finishDirectoryPath: pathString pathComponent: comp];
    
    // Only cache path names for directories.
    [cachedPathStrings addObject: pathString];
    [cachedFileItems addObject: item];
  }
  
  return pathString;
}

- (void) clearCache {
  [cachedPathStrings removeAllObjects];
  [cachedFileItems removeAllObjects];
}

@end


@implementation FileItemPathStringCache (PrivateMethods)

- (NSString *)finishDirectoryPath: (NSString *)path 
                pathComponent: (NSString *)comp {

  // Check if a trailing slash should be added to ensure that a slash is only
  // added when needed, e.g. when there is not a valid one already. Note, 
  // cannot check for trailing slash directly, as path components (as 
  // represented to the user) may actual contain/end with slashes. 

  if ( addTrailingSlashToDirectoryPaths 
       && comp != nil
       && ! [path isEqualToString: @"/"] ) {
    return [path stringByAppendingString: @"/"];
  }
  else {
    return path;
  }
}

- (void) fillCacheToItem: (FileItem *) item {
  NSAssert(item != nil, @"Item must be non-nil.");
  
  NSString  *pathString;
  NSString  *comp = [item pathComponent];
  
  if ([item parentDirectory] != nil) {
    [self fillCacheToItem: [item parentDirectory]];
    pathString = ( (comp != nil) ? [[cachedPathStrings lastObject] 
                                       stringByAppendingPathComponent: comp]
                                 : [cachedPathStrings lastObject] );
  }
  else {
    pathString = (comp != nil) ? comp : @"";
    NSAssert([cachedPathStrings count] == 0, @"Cache should be empty.");
  }
  
  pathString = [self finishDirectoryPath: pathString pathComponent: comp];
  
  [cachedPathStrings addObject: pathString];
  [cachedFileItems addObject: item];
}

@end
