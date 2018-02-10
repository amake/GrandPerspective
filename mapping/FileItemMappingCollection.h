#import <Cocoa/Cocoa.h>

@protocol FileItemMappingScheme;

/* A collection of file item mapping schemes.
 */
@interface FileItemMappingCollection : NSObject {

  NSMutableDictionary  *schemesDictionary;

}

+ (FileItemMappingCollection *)defaultFileItemMappingCollection;

- (instancetype) initWithDictionary:(NSMutableDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

- (void) addFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)scheme
                              key:(NSString *)key;
- (void) removeFileItemMappingSchemeForKey:(NSString *)key;

@property (nonatomic, readonly, copy) NSArray *allKeys;
- (NSObject <FileItemMappingScheme> *)fileItemMappingSchemeForKey:(NSString *)key;

@end
