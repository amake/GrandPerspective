#import "FileSizeMeasureCollection.h"

#import "TreeBuilder.h"

@implementation FileSizeMeasureCollection

+ (FileSizeMeasureCollection*) defaultFileSizeMeasureCollection {
  static  FileSizeMeasureCollection  
    *defaultFileSizeMeasureCollectionInstance = nil;

  if (defaultFileSizeMeasureCollectionInstance == nil) {
    defaultFileSizeMeasureCollectionInstance = 
      [[FileSizeMeasureCollection alloc] initWithKeys:
          [NSArray arrayWithObjects: LogicalFileSize, PhysicalFileSize, nil]];
  }
  
  return defaultFileSizeMeasureCollectionInstance;
}


// Overrides designated initialiser
- (id) init {
  return [self initWithKeys: [NSArray array]];
}

- (id) initWithKeys: (NSArray *)keysVal {
  if (self = [super init]) {
    keys = [keysVal retain];
  }
  return self;
}

- (void) dealloc {
  [keys release];
  
  [super dealloc];
}


- (NSArray*) allKeys {
  return keys;
}

@end
