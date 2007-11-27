#import "ItemPathBuilder.h"

#import "FileItem.h"
#import "ItemPathModel.h"
#import "TreeLayoutBuilder.h"


@implementation ItemPathBuilder

// Overrides super's designated initialiser.
- (id) init {
  NSAssert(NO, @"Use -initWithPathModel: instead.");
}

- (id) initWithPathModel:(ItemPathModel*)pathModelVal {
  if (self = [super init]) {
    pathModel = [pathModelVal retain];    
  }
  
  return self;
}

- (void) dealloc {
  [pathModel release];

  [super dealloc];
}

- (void) buildVisiblePathToPoint:(NSPoint)point 
           usingLayoutBuilder:(TreeLayoutBuilder*)layoutBuilder 
           bounds:(NSRect)bounds {
  // Don't generate notifications while the path is being built.
  [pathModel suppressSelectedItemChangedNotifications:YES];
  
  [pathModel clearVisiblePath];
  buildTargetPoint = point;

  [layoutBuilder layoutItemTree:[pathModel visibleTree] inRect:bounds
                   traverser:self];
  
  [pathModel suppressSelectedItemChangedNotifications:NO];
}


- (BOOL) descendIntoItem:(Item*)item atRect:(NSRect)rect depth:(int)depth {
  if (!NSPointInRect(buildTargetPoint, rect)) {
    return NO;
  }

  if (depth > 0) {
    [pathModel extendVisiblePath:item];
  }

  // track path further
  return YES;
}

- (void) emergedFromItem:(Item*)item {
  // void
}

@end // @implementation ItemPathBuilder
