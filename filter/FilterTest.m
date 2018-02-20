#import "FilterTest.h"


@implementation FilterTest

+ (instancetype) filterTestWithName:(NSString *)name fileItemTest:(FileItemTest *)fileItemTest {
  return [[[FilterTest alloc] initWithName: name fileItemTest: fileItemTest] autorelease];
}

// Overrides designated initialiser.
- (instancetype) init {
  NSAssert(NO, @"Use initWithName:fileItemTest: instead.");
  return [self initWithName: nil fileItemTest: nil];
}

// Designated initialiser.
- (instancetype) initWithName:(NSString *)name fileItemTest:(FileItemTest *)fileItemTest {
  if (self = [super init]) {
    _name = [name retain];
    _fileItemTest = [fileItemTest retain];
  }
  return self;
}

- (void) dealloc {
  [_name release];
  [_fileItemTest release];
  
  [super dealloc];
}

@end
