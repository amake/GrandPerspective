#import "ItemSizeTest.h"

#import "FileItem.h"
#import "FileItemTestVisitor.h"


@implementation ItemSizeTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithLowerBound:upperBound: instead.");
  return [self initWithLowerBound: 0 upperBound: 0];
}

- (instancetype) initWithLowerBound:(ITEM_SIZE)lowerBound {
  return [self initWithLowerBound: lowerBound upperBound: ULONG_LONG_MAX];
}

- (instancetype) initWithUpperBound:(ITEM_SIZE)upperBound {
  return [self initWithLowerBound: 0 upperBound: upperBound];
}

- (instancetype) initWithLowerBound:(ITEM_SIZE)lowerBound
                         upperBound:(ITEM_SIZE)upperBound {
  if (self = [super init]) {
    _lowerBound = lowerBound;
    _upperBound = upperBound;
  }
  
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    id  object;
    
    object = dict[@"lowerBound"];
    _lowerBound = (object == nil) ? 0 : [object unsignedLongLongValue];
     
    object = dict[@"upperBound"];
    _upperBound = (object == nil) ? ULONG_LONG_MAX : [object unsignedLongLongValue];
  }
  
  return self;
}

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"ItemSizeTest";
  
  if ([self hasLowerBound]) {
    dict[@"lowerBound"] = @(self.lowerBound);
  }
  if ([self hasUpperBound]) {
    dict[@"upperBound"] = @(self.upperBound);
  }
}


- (BOOL) hasLowerBound {
  return self.lowerBound > 0;
}

- (BOOL) hasUpperBound {
  return self.upperBound < ULONG_LONG_MAX;
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  return
    ([item itemSize] >= self.lowerBound &&
     [item itemSize] <= self.upperBound) ? TEST_PASSED : TEST_FAILED;
}

- (BOOL) appliesToDirectories {
  return YES;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemSizeTest: self];
}


- (NSString *)description {
  if ([self hasLowerBound]) {
    if ([self hasUpperBound]) {
      NSString  *fmt = 
        NSLocalizedStringFromTable(@"size is between %@ and %@", @"Tests",
                                   @"Size test with 1: lower bound, and 2: upper bound");
      return [NSString stringWithFormat: fmt, 
                [FileItem stringForFileItemSize: self.lowerBound],
                [FileItem stringForFileItemSize: self.upperBound]];
    }
    else {
      NSString  *fmt = 
        NSLocalizedStringFromTable(@"size is larger than %@", @"Tests",
                                   @"Size test with 1: lower bound");
      
      return [NSString stringWithFormat: fmt, [FileItem stringForFileItemSize: self.lowerBound]];
    }
  }
  else {
    if ([self hasUpperBound]) {
      NSString  *fmt = 
        NSLocalizedStringFromTable(@"size is smaller than %@", @"Tests",
                                   @"Size test with 1: upper bound");
      return [NSString stringWithFormat: fmt, [FileItem stringForFileItemSize: self.upperBound]];
    }
    else {
      return NSLocalizedStringFromTable(@"any size", @"Tests",
                                        @"Size test without any bounds");
    }
  }
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"ItemSizeTest"],
           @"Incorrect value for class in dictionary.");

  return [[[ItemSizeTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end // @implementation ItemSizeTest
