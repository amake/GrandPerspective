#import "FilterTest.h"


@implementation FilterTest

+ (instancetype) filterTestWithName:(NSString *)name fileItemTest:(FileItemTest *)test {
  return [[[FilterTest alloc] initWithName: name fileItemTest: test] autorelease];
}

// Overrides designated initialiser.
- (instancetype) init {
  NSAssert(NO, @"Use initWithName:fileItemTest: instead.");
  return [self initWithName: nil fileItemTest: nil];
}

// Designated initialiser.
- (instancetype) initWithName:(NSString *)nameVal fileItemTest:(FileItemTest *)testVal {
  if (self = [super init]) {
    name = [nameVal retain];
    test = [testVal retain];
  }
  return self;
}

- (void) dealloc {
  [name release];
  [test release];
  
  [super dealloc];
}


- (NSString *)name {
  return name;
}

- (FileItemTest *)fileItemTest {
  return test;
}

@end
