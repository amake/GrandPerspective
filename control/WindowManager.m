#import "WindowManager.h"


@interface WindowManager (PrivateMethods)

- (NSString *) makeTitleUnique: (NSString *)title;
- (NSString *) stripTitle: (NSString *)title;

@end


@implementation WindowManager

- (id) init {
  if (self = [super init]) {
    titleLookup = [[NSMutableDictionary alloc] initWithCapacity: 8];
    
    nextWindowPosition = NSZeroPoint;
  }
  return self;
}

- (void) dealloc {
  [super dealloc];
  
  [titleLookup release];
}

- (void) addWindow: (NSWindow *)window usingTitle: (NSString *)title {
  nextWindowPosition = [window cascadeTopLeftFromPoint: nextWindowPosition]; 
  [window setTitle: [self makeTitleUnique: title]];
}

@end


@implementation WindowManager (PrivateMethods)

- (NSString *) makeTitleUnique: (NSString *)title {
  NSString*  strippedTitle = [self stripTitle: title];

  NSNumber*  count = [titleLookup objectForKey: strippedTitle];
  NSUInteger  newCount = (count == nil) ? 1 : [count unsignedIntegerValue] + 1;

  [titleLookup setObject: [NSNumber numberWithUnsignedInteger: newCount]
                  forKey: strippedTitle];
    
  if (newCount == 1) {
    // First use of this (base) title
    
    return strippedTitle;
  }
  else {
    // This title has been used before. Append the count to make it unique.
    
    NSMutableString*  uniqueTitle = [NSMutableString stringWithCapacity:
                                      [strippedTitle length] + 5];
                                      
    [uniqueTitle setString: strippedTitle];
    [uniqueTitle appendFormat: @" [%lu]", (unsigned long)newCount];
    
    return uniqueTitle;
  }
}


- (NSString *) stripTitle: (NSString *)title {
  NSUInteger  pos = [title length];
  NSCharacterSet*  digitSet = [NSCharacterSet decimalDigitCharacterSet]; 

  if ( pos-- == 0 ||
       [title characterAtIndex: pos] != ']' ||
       pos-- == 0 ||
       ! [digitSet characterIsMember: [title characterAtIndex: pos]] ) {
    // Does not end with DIGIT + "]"
    return title;
  }
  
  // Keep stripping digits.
  while ( pos > 0 &&
          [digitSet characterIsMember: [title characterAtIndex: pos - 1]] ) {
    pos--;
  }

  if ( pos-- == 0 ||
       [title characterAtIndex: pos] != '[' ||
       pos-- == 0 ||
       [title characterAtIndex: pos] != ' ' ) {
    // Does not contain " [" directly in front of digits.
    return title;
  }
  
  // Return the title, with " [" + DIGITS + "]" stripped.
  return [title substringToIndex: pos];
}

@end // @implementation WindowManager (PrivateMethods)
