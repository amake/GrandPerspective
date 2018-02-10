#import <Cocoa/Cocoa.h>


/* Abstract class for tests on string values.
 */
@interface StringTest : NSObject {
}

+ (StringTest *)stringTestFromDictionary:(NSDictionary *)dict;

- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;
@end


@interface StringTest (AbstractMethods)

- (BOOL) testString:(NSString *)string;

- (NSString *)descriptionWithSubject:(NSString *)subject;

// Used for storing object to preferences.
- (NSDictionary *)dictionaryForObject;

@end


@interface StringTest (ProtectedMethods)

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict;

@end // @interface StringTest (ProtectedMethods)
