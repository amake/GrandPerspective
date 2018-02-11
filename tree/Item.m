#import "Item.h"

#import "PreferencesPanelControl.h"

// The supported memory-zone options for storing trees.
NSString  *DefaultZone = @"default";
NSString  *DedicatedSharedZone = @"dedicated shared";
NSString  *DedicatedPrivateZone = @"dedicated private";

@implementation Item

static NSZone  *dedicatedSharedZone = nil;

+ (NSZone *)zoneForTree {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString  *memoryZone = [userDefaults stringForKey: TreeMemoryZoneKey];
  NSLog(@"Allocating tree in %@ memory zone.", memoryZone);
  if ([memoryZone isEqualToString: DefaultZone]) {
    return NSDefaultMallocZone();
  } 
  else if ([memoryZone isEqualToString: DedicatedSharedZone]) {
    if (dedicatedSharedZone == nil) {
      dedicatedSharedZone = NSCreateZone(8192 * 16, 4096 * 16, YES);
    }
    return dedicatedSharedZone;
  }
  else if ([memoryZone isEqualToString: DedicatedPrivateZone]) {
    return NSCreateZone(8192 * 16, 4096 * 16, NO);
  }

  NSAssert2(NO, @"Unrecognized value for %@: \"%@\"", TreeMemoryZoneKey, memoryZone);
  return nil;
}

+ (BOOL) disposeZoneAfterUse:(NSZone *)zone {
  return (zone != NSDefaultMallocZone() && zone != dedicatedSharedZone);
}


// Overrides super's designated initialiser.
- (instancetype) init {
  return [self initWithItemSize:0];
}

- (instancetype) initWithItemSize:(ITEM_SIZE)itemSize {
  if (self = [super init]) {
    _itemSize = itemSize;
  }
  
  return self;
}


- (FILE_COUNT) numFiles {
  return 0;
}

- (void) setItemSize:(ITEM_SIZE)itemSize {
  NSAssert(_itemSize == 0, @"Cannot change itemSize after it has been set");
  _itemSize = itemSize;
}


- (BOOL) isVirtual {
  return NO;
}


- (NSString *)description {
  return [NSString stringWithFormat:@"Item(size=%qu)", self.itemSize];
}

@end
