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

- (instancetype) initWithName:(NSString *)name inverted:(BOOL)inverted {
  if (self = [super init]) {
    _name = [[NSString alloc] initWithString: name]; // Ensure it's immutable
    _inverted = inverted;
  }

  return self;
}

- (void) dealloc {
  [_name release];
  
  [super dealloc];
}


- (NSDictionary *)dictionaryForObject {
  return @{@"inverted": @(self.isInverted), @"name": self.name};
}

@end // @implementation FilterTestRef
