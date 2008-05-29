#import "ItemTypeTest.h"

#import "TestDescriptions.h"
#import "PlainFileItem.h"
#import "UniformType.h"
#import "UniformTypeInventory.h"


@implementation ItemTypeTest

// Overrides designated initialiser
- (id) init {
  NSAssert(NO, @"Use initWithMatchTargets: instead.");
}

- (id) initWithMatchTargets: (NSArray *)matchesVal {
  return [self initWithMatchTargets: matchesVal strict: NO];
}

- (id) initWithMatchTargets: (NSArray *)matchesVal strict: (BOOL) strictVal {
  if (self = [super init]) {
    // Make the array immutable
    matches = [[NSArray alloc] initWithArray: matchesVal];

    strict = strictVal;
  }
  
  return self;
}


- (void) dealloc {
  [matches release];
  
  [super dealloc];
}


// Note: Special case. Does not call own designated initialiser. It should
// be overridden and only called by initialisers with the same signature.
- (id) initWithPropertiesFromDictionary: (NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *utis = [dict objectForKey: @"matches"];
    unsigned  numMatches = [utis count];

    UniformTypeInventory  *typeInventory = 
      [UniformTypeInventory defaultUniformTypeInventory];

    NSMutableArray  *tmpMatches =
      [NSMutableArray arrayWithCapacity: numMatches];
    
    unsigned  i = 0;
    while (i < numMatches) {
      UniformType  *type = 
        [typeInventory uniformTypeForIdentifier: [utis objectAtIndex: i]];
        
      if (type != nil) {
        [tmpMatches addObject: type];
      }
      
      i++;
    }
    
    // Make the array immutable
    matches = [[NSArray alloc] initWithArray: tmpMatches];
    
    strict = [[dict objectForKey: @"strict"] boolValue];
  }
  
  return self;
}


- (void) addPropertiesToDictionary: (NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  [dict setObject: @"ItemTypeTest" forKey: @"class"];
  
  UniformTypeInventory  *typeInventory = 
    [UniformTypeInventory defaultUniformTypeInventory];
  unsigned  numMatches = [matches count];

  NSMutableArray  *utis = [NSMutableArray arrayWithCapacity: numMatches];
  unsigned  i = 0;
  while (i < numMatches) {
    [utis addObject: 
       [((UniformType *)[matches objectAtIndex: i]) uniformTypeIdentifier]];
  }

  [dict setObject: utis forKey: @"matches"];
  
  [dict setObject: [NSNumber numberWithBool: strict] forKey: @"strict"];
}


- (NSArray *) matchTargets {
  return matches;
}

- (BOOL) isStrict {
  return strict;
}


- (BOOL) testFileItem: (FileItem *)item context: (id)context {
  if ([item isDirectory]) {
    // Test does not apply to directories
    return YES;
  }
  
  UniformType  *type = [((PlainFileItem *)item) uniformType];
  NSSet  *ancestorTypes = strict ? nil : [type ancestorTypes];
    
  int  i = [matches count];
  while (--i >= 0) {
    UniformType  *matchType = [matches objectAtIndex: i];
    if (type == matchType || [ancestorTypes containsObject: matchType]) {
      return YES;
    }
  }
  
  return NO;
}


- (NSString *) description {
  NSString  *matchesDescr = descriptionForMatches( matches );
  NSString  *format =  
    NSLocalizedStringFromTable( 
           @"type conforms to %@", @"Tests",
           @"Filetype test with 1: match targets" );
  
  return [NSString stringWithFormat: format, matchesDescr];
}


+ (NSObject *) objectFromDictionary: (NSDictionary *)dict {  
  NSAssert([[dict objectForKey: @"class"] isEqualToString: @"ItemTypeTest"],
             @"Incorrect value for class in dictionary.");

  return [[[ItemTypeTest alloc] initWithPropertiesFromDictionary: dict]
           autorelease];
}

@end
