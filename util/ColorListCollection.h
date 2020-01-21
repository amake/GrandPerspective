#import <Cocoa/Cocoa.h>

@interface ColorListCollection : NSObject {

  NSMutableDictionary  *colorListDictionary;

}

+ (ColorListCollection *)defaultColorListCollection;

- (void) addColorList:(NSColorList *)colorList key:(NSString *)key;
- (void) removeColorListForKey:(NSString *)key;

@property (nonatomic, readonly, copy) NSArray *allKeys;

- (NSColorList *)colorListForKey:(NSString *)key;

// Returns a fallback color list that can be used when a palette for a specified key returned nil,
// either because the palette was removed or it could not be loaded successfully.
- (NSColorList *)fallbackColorList;

@end
