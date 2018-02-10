#import "ColorListCollection.h"


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
         
      [instance addColorList: colorList key: name];
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

@end
