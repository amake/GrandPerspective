#import "NamedFilter.h"

#import "Filter.h"


@implementation NamedFilter

+ (NamedFilter *)emptyFilterWithName:(NSString *)name {
  return [[[NamedFilter alloc] initWithFilter: [Filter filter] name: name] autorelease];
}

+ (NamedFilter *)namedFilter:(Filter *)filter name:(NSString *)name {
  return [[[NamedFilter alloc] initWithFilter: filter name: name] autorelease];
}


// Overrides designated initialiser.
- (instancetype) init {
  NSAssert(NO, @"Use initWithFilter:name: instead.");
  return [self initWithFilter: nil name: nil];
}

- (instancetype) initWithFilter:(Filter *)filter name:(NSString *)name {
  if (self = [super init]) {
    _filter = [filter retain];
    _name = [name retain];
  }
  return self;
}

- (void) dealloc {
  [_filter release];
  [_name release];
  
  [super dealloc];
}

- (NSString *)localizedName {
  return [[NSBundle mainBundle] localizedStringForKey: self.name value: nil table: @"Names"];
}

@end
