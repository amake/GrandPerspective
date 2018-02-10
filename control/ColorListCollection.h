#import <Cocoa/Cocoa.h>


@interface ColorListCollection : NSObject {

  NSMutableDictionary  *colorListDictionary;

}

+ (ColorListCollection *)defaultColorListCollection;

- (void) addColorList:(NSColorList *)colorList key:(NSString *)key;
- (void) removeColorListForKey:(NSString *)key;

@property (nonatomic, readonly, copy) NSArray *allKeys;
- (NSColorList *)colorListForKey:(NSString *)key;

@end
