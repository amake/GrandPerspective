#import "ItemPathModel.h"


#import "FileItem.h"


@interface ItemPathModel (PrivateMethods)

- (void) postVisibleItemPathChanged;
- (void) postVisibleItemTreeChanged;

@end


@implementation ItemPathModel

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithTree instead.");
}

- (id) initWithTree:(Item*)itemTreeRoot {
  if (self = [super init]) {
    path = [[NSMutableArray alloc] initWithCapacity:64];

    NSAssert(![itemTreeRoot isVirtual], @"Tree root must not be virtual");
    
    [path addObject:itemTreeRoot];

    visibleTreeRootIndex = 0;
    lastFileItemIndex = 0;
  }
  return self;
}

- (void) dealloc {
  NSLog(@"ItemPathModel-dealloc");
  [path release];
  
  [super dealloc];
}


- (NSArray*) invisibleFileItemPath {
  NSMutableArray  *invisible = [NSMutableArray arrayWithCapacity:8];

  int  i = 0;
  while (i <= visibleTreeRootIndex) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [invisible addObject:[path objectAtIndex:i]];
    }
    i++;
  }
  
  return invisible;
}

- (NSArray*) visibleFileItemPath {
  NSMutableArray  *visible = [NSMutableArray arrayWithCapacity:8];

  int  i = visibleTreeRootIndex + 1, max = [path count];
  while (i < max) {
    if (![[path objectAtIndex:i] isVirtual]) {
      [visible addObject:[path objectAtIndex:i]];
    }
    i++;
  }
  return visible;
}


- (NSArray*) invisibleItemPath {
  return [path subarrayWithRange:NSMakeRange(0, visibleTreeRootIndex + 1)];
}


- (NSArray*) visibleItemPath {
  return [path subarrayWithRange:
                 NSMakeRange(visibleTreeRootIndex + 1,
                             [path count] - visibleTreeRootIndex - 1)];
}


- (NSArray*) itemPath {
  // Note: For efficiency returning path directly, instead of an (immutable)
  // copy. This is done so that there is not too much overhead associated
  // with invoking ItemPathDrawer -drawItemPath:...: many times in short
  // successsion.
  return path;
}


- (FileItem*) fileItemPathEndPoint {
  return [path objectAtIndex:lastFileItemIndex];
}


- (void) suppressItemPathChangedNotifications:(BOOL)option {
  if (option) {
    if (lastNotifiedPathEndPoint != nil) {
      return; // Already suppressing notifications.
    }
    lastNotifiedPathEndPoint = [path lastObject];
  }
  else {
    if (lastNotifiedPathEndPoint == nil) {
      return; // Already instantanously generating notifications.
    }
    
    if (lastNotifiedPathEndPoint != [path lastObject]) {
      [self postVisibleItemPathChanged];
    }
    lastNotifiedPathEndPoint = nil;
  }
}

- (BOOL) clearVisibleItemPath {
  int  num = [path count] - visibleTreeRootIndex - 1;

  if (num > 0) {
    [path removeObjectsInRange:NSMakeRange(visibleTreeRootIndex + 1, num)];
    lastFileItemIndex = visibleTreeRootIndex;

    if (lastNotifiedPathEndPoint == nil) { // Notifications not suppressed.
      [self postVisibleItemPathChanged];
    }
    
    return YES;
  }

  return NO;
}


- (void) extendVisibleItemPath:(Item*)nextItem {
  if (! [nextItem isVirtual]) {
    lastFileItemIndex = [path count];
  }
  
  [path addObject:nextItem];
  
  if (lastNotifiedPathEndPoint == nil) { // Notifications not suppressed.
    [self postVisibleItemPathChanged];
  }
}



- (FileItem*) visibleItemTree {
  return [path objectAtIndex:visibleTreeRootIndex];
}


- (BOOL) canMoveTreeViewUp {
  return (visibleTreeRootIndex > 0);
}

- (BOOL) canMoveTreeViewDown {
  return (visibleTreeRootIndex < lastFileItemIndex);
}

- (void) moveTreeViewUp {
  NSAssert([self canMoveTreeViewUp], @"Cannot move up.");

  do {
    visibleTreeRootIndex--;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);
  
  [self postVisibleItemTreeChanged];
}

- (void) moveTreeViewDown {
  NSAssert([self canMoveTreeViewDown], @"Cannot move down.");

  do {
    visibleTreeRootIndex++;
  } while ([[path objectAtIndex:visibleTreeRootIndex] isVirtual]);  

  [self postVisibleItemTreeChanged];
}

@end


@implementation ItemPathModel (PrivateMethods)

- (void) postVisibleItemPathChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemPathChanged" object:self];
}

- (void) postVisibleItemTreeChanged {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"visibleItemTreeChanged" object:self];
}

@end