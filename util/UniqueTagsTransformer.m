#import "UniqueTagsTransformer.h"


@implementation UniqueTagsTransformer

+ (Class) transformedValueClass {
  return [NSNumber class];
}

+ (BOOL) allowsReverseTransformation {
  return YES; 
}


+ (UniqueTagsTransformer *) defaultUniqueTagsTransformer {
  static UniqueTagsTransformer  *defaultUniqueTagsTransformer = nil;
  
  if (defaultUniqueTagsTransformer == nil) {
    defaultUniqueTagsTransformer = [[UniqueTagsTransformer alloc] init];
  }
  
  return defaultUniqueTagsTransformer;
}


- (instancetype) init {
  if (self = [super init]) {
    valueToTag = [[NSMutableDictionary alloc] initWithCapacity: 64];
    tagToValue = [[NSMutableDictionary alloc] initWithCapacity: 64];
    
    nextTag = 0;
  }
  
  return self;
}

- (void) dealloc {
  [valueToTag release];
  [tagToValue release];
  
  [super dealloc];
}


- (id) transformedValue:(id) value {
  if (value == nil) {
    // Gracefully handle nil values.
    return nil;
  }

  id  tag = valueToTag[value];
 
  if (tag == nil) {
    tag = @(nextTag++);

    valueToTag[value] = tag;
    tagToValue[tag] = value;
  }
  
  return tag;
}

- (id) reverseTransformedValue:(id) tag {
  id  value = tagToValue[tag];
  
  NSAssert(value != nil, @"Unknown tag value.");
  
  return value;
}


- (void) addLocalisedNames:(NSArray *)names
                   toPopUp:(NSPopUpButton *)popUp
                    select:(NSString *)selectName
                     table:(NSString *)tableName {
  NSEnumerator  *nameEnum = [names objectEnumerator];
  NSString  *name;
  
  while (name = [nameEnum nextObject]) {
    [self addLocalisedName: name 
                   toPopUp: popUp
                    select: [name isEqualToString: selectName]
                     table: tableName];
  }
}

- (void) addLocalisedName:(NSString *)name 
                  toPopUp:(NSPopUpButton *)popUp
                   select:(BOOL) select
                    table:(NSString *)tableName {
  NSBundle  *mainBundle = [NSBundle mainBundle];
  NSString  *localizedName = [mainBundle localizedStringForKey: name value: nil table: tableName];

  int  tag = [[self transformedValue: name] intValue];
  
  // Find location where to insert item so that list remains sorted by localized name
  // Note: Using linear search, which is OK as long as list is relatively small.
  int  index = 0;
  while (index < popUp.numberOfItems) {
    NSString  *otherName = [popUp itemAtIndex: index].title;
    if ([localizedName compare: otherName] == NSOrderedAscending) {
      break;
    }
    index++;
  }
  
  [popUp insertItemWithTitle: localizedName atIndex: index];
  [popUp itemAtIndex: index].tag = tag;
  
  if (select) {
    [popUp selectItemAtIndex: index];
  }
}


- (NSString *)nameForTag:(NSUInteger)tag {
  return [self reverseTransformedValue: @(tag)];
}

/* Returns the tag for the locale-independent name.
 */
- (NSUInteger) tagForName:(NSString *)name {
  return [[self transformedValue: name] intValue];
}

@end
