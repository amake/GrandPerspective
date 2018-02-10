#import "FilterTestRef.h"


@implementation FilterTestRef

+ (id) filterTestWithName:(NSString *)name {
  return [[[FilterTestRef alloc] initWithName: name] autorelease];
}

+ (id) filterTestWithName:(NSString *)name inverted:(BOOL) inverted {
  return [[[FilterTestRef alloc] initWithName: name inverted: inverted] autorelease];
}


+ (FilterTestRef *)filterTestRefFromDictionary:(NSDictionary *)dict {
  return 
    [FilterTestRef filterTestWithName: dict[@"name"]
                             inverted: [dict[@"inverted"] boolValue]];
}


// Overrides designated initialiser.
- (instancetype) init {
  NSAssert(NO, @"Use initWithName: instead.");
  return [self initWithName: nil];
}

- (instancetype) initWithName:(NSString *)nameVal {
  return [self initWithName: nameVal inverted: NO];
}

- (instancetype) initWithName:(NSString *)nameVal inverted:(BOOL)invertedVal {
  if (self = [super init]) {
    name = [[NSString alloc] initWithString: nameVal]; // Ensure it's immutable
    inverted = invertedVal;
  }

  return self;
}

- (void) dealloc {
  [name release];
  
  [super dealloc];
}


- (NSString *) name {
  return name;
}

- (BOOL) isInverted {
  return inverted;
}


- (NSDictionary *)dictionaryForObject {
  return @{@"inverted": @(inverted), @"name": name};
}

@end // @implementation FilterTestRef
