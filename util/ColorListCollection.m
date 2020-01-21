#import "ColorListCollection.h"

#import "PreferencesPanelControl.h"

NSString* fallbackColorListKey = @"Fallback";
NSString* fallbackColorListName = @"Fallback";

static NSString*  hexChars = @"0123456789ABCDEF";

float valueOfHexPair(NSString* hexString) {
  int  val = 0;
  int  i;
  for (i = 0; i < [hexString length]; i++) {
    val = val * 16;
    NSRange  r = [hexChars rangeOfString: [hexString substringWithRange: NSMakeRange(i, 1)]
                                 options: NSCaseInsensitiveSearch];
    val += r.location;
  }

  return (val / 255.0);
}

NSColor* colorForHexString(NSString* hexColor) {
  float  r = valueOfHexPair([hexColor substringWithRange: NSMakeRange(0, 2)]);
  float  g = valueOfHexPair([hexColor substringWithRange: NSMakeRange(2, 2)]);
  float  b = valueOfHexPair([hexColor substringWithRange: NSMakeRange(4, 2)]);

  return [NSColor colorWithDeviceRed:r green:g blue:b alpha:0];
}

NSColorList* createFallbackPalette() {
  NSColorList  *colorList = [[[NSColorList alloc] initWithName: fallbackColorListName] autorelease];

  // Hardcoded CoffeeBeans palette
  NSArray  *colors = [NSArray arrayWithObjects: @"CC3333", @"CC9933", @"FFCC66", @"CC6633",
                                                @"CC6666", @"993300", @"666600", nil];

  int count = 0;
  for (id colorString in colors) {
    [colorList insertColor: colorForHexString(colorString) key: colorString atIndex: count++];
  }

  return colorList;
}

@interface ColorListCollection (PrivateMethods)
- (bool) isEmpty;
@end

@implementation ColorListCollection

+ (ColorListCollection *)defaultColorListCollection {
  static ColorListCollection  *defaultColorListCollectionInstance = nil;

  if (defaultColorListCollectionInstance == nil) {
    ColorListCollection  *instance = [[[ColorListCollection alloc] init] autorelease];
    
    NSBundle  *bundle = [NSBundle mainBundle];
    NSArray  *colorListPaths = [bundle pathsForResourcesOfType: @".clr" inDirectory: @"Palettes"];
    NSEnumerator  *pathEnum = [colorListPaths objectEnumerator];
    NSString  *path;
    while (path = [pathEnum nextObject]) {
      NSString  *name = path.lastPathComponent.stringByDeletingPathExtension;

      NSColorList  *colorList = [[NSColorList alloc] initWithName: name fromFile: path];
      if (colorList != nil) {
        [instance addColorList: colorList key: name];
      }
    }

    if ([instance isEmpty]) {
      // Should not happen, but on old versions of OS X reading can fail (see Bug #81)
      NSLog(@"Failed to load any palette. Adding fallback palette");
      [instance addColorList: createFallbackPalette() key: fallbackColorListKey];
    }
    
    defaultColorListCollectionInstance = [instance retain];
  }
  
  return defaultColorListCollectionInstance;
}


// Overrides designated initialiser.
- (instancetype) init {
  if (self = [super init]) {
    colorListDictionary = [[NSMutableDictionary alloc] initWithCapacity: 8];
  }
  
  return self;
}

- (void) dealloc {
  [colorListDictionary release];

  [super dealloc];
}


- (void) addColorList:(NSColorList *)colorList key:(NSString *)key {
  colorListDictionary[key] = colorList;
}

- (void) removeColorListForKey:(NSString *)key {
  [colorListDictionary removeObjectForKey: key];
}


- (NSArray *)allKeys {
  return colorListDictionary.allKeys;
}

- (NSColorList *)colorListForKey:(NSString *)key {
  return colorListDictionary[key];
}

- (NSColorList *)fallbackColorList {
  NSColorList  *fallback = nil;

  // First try the preferred default as specified by the user
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  fallback = [self colorListForKey: [ud stringForKey: DefaultColorPaletteKey]];

  // Otherwise try a hardcoded default
  if (fallback == nil) {
    fallback = [self colorListForKey: @"CoffeeBeans"];
  }

  // Otherwise return an arbitrary palette. If none could be loaded, this will be the fallback
  // hardcode palette returned by createFallbackPalette().
  if (fallback == nil) {
    fallback = [self colorListForKey: self.allKeys[0]];
  }

  return fallback;
}

@end // @implementation ColorListCollection

@implementation ColorListCollection (PrivateMethods)

- (bool) isEmpty {
  return colorListDictionary.count == 0;
}

@end
