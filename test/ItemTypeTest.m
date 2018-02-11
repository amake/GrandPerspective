#import "ItemTypeTest.h"

#import "TestDescriptions.h"
#import "PlainFileItem.h"
#import "FileItemTestVisitor.h"
#import "UniformType.h"
#import "UniformTypeInventory.h"


@interface ItemTypeTest (PrivateMethods)

@property (nonatomic, readonly, copy) NSArray *matchesAsStrings;

@end


@implementation ItemTypeTest

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithMatchTargets: instead.");
  return [self initWithMatchTargets: nil];
}

- (instancetype) initWithMatchTargets:(NSArray *)matches {
  return [self initWithMatchTargets: matches strict: NO];
}

- (instancetype) initWithMatchTargets:(NSArray *)matches strict:(BOOL)strict {
  if (self = [super init]) {
    // Make the array immutable
    _matchTargets = [[NSArray alloc] initWithArray: matches];

    _strict = strict;
  }
  
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *utis = dict[@"matches"];
    NSUInteger  numMatches = utis.count;

    UniformTypeInventory  *typeInventory = [UniformTypeInventory defaultUniformTypeInventory];

    NSMutableArray  *tmpMatches = [NSMutableArray arrayWithCapacity: numMatches];
    
    NSUInteger  i = 0;
    while (i < numMatches) {
      UniformType  *type = [typeInventory uniformTypeForIdentifier: utis[i]];
        
      if (type != nil) {
        [tmpMatches addObject: type];
      }
      
      i++;
    }
    
    // Make the array immutable
    _matchTargets = [[NSArray alloc] initWithArray: tmpMatches];
    
    _strict = [dict[@"strict"] boolValue];
  }
  
  return self;
}

- (void) dealloc {
  [_matchTargets release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"ItemTypeTest";
  dict[@"matches"] = [self matchesAsStrings];
  dict[@"strict"] = @(self.strict);
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  if ([item isDirectory]) {
    // Test does not apply to directories
    return TEST_NOT_APPLICABLE;
  }
  
  UniformType  *type = [((PlainFileItem *)item) uniformType];
  NSSet  *ancestorTypes = self.isStrict ? nil : [type ancestorTypes];
    
  NSUInteger  i = self.matchTargets.count;
  while (i-- > 0) {
    UniformType  *matchType = self.matchTargets[i];
    if (type == matchType || [ancestorTypes containsObject: matchType]) {
      return TEST_PASSED;
    }
  }
  
  return TEST_FAILED;
}

- (BOOL) appliesToDirectories {
  return NO;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemTypeTest: self];
}


- (NSString *)description {
  NSString  *matchesDescr = descriptionForMatches( [self matchesAsStrings] );
  NSString  *format = (self.isStrict
                       ? NSLocalizedStringFromTable(
                           @"type equals %@", @"Tests",
                           @"Filetype test with 1: match targets")
                       : NSLocalizedStringFromTable(
                           @"type conforms to %@", @"Tests",
                           @"Filetype test with 1: match targets"));
  
  return [NSString stringWithFormat: format, matchesDescr];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict { 
  NSAssert([dict[@"class"] isEqualToString: @"ItemTypeTest"],
           @"Incorrect value for class in dictionary.");

  return [[[ItemTypeTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end


@implementation ItemTypeTest (PrivateMethods)

- (NSArray *)matchesAsStrings {
  NSUInteger  numMatches = self.matchTargets.count;
  NSMutableArray  *utis = [NSMutableArray arrayWithCapacity: numMatches];

  NSUInteger  i = 0;
  while (i < numMatches) {
    [utis addObject: 
       [((UniformType *)self.matchTargets[i]) uniformTypeIdentifier]];
    i++;
  }
  
  return utis;
}

@end // @implementation ItemTypeTest (PrivateMethods)

