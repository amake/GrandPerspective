#import <Cocoa/Cocoa.h>

/* A test that is part of a Filter. Instances of this object are immutable. However, instances of
 * the MutableFilterTestRef subclass are not.
 */
@interface FilterTestRef : NSObject {
  NSString  *name;

  // Is the test inverted?
  BOOL  inverted;
}

+ (id) filterTestWithName:(NSString *)name;
+ (id) filterTestWithName:(NSString *)name inverted:(BOOL)inverted;

/* Creates a filter from a dictionary as generated by -dictionaryForObject.
 */
+ (FilterTestRef *)filterTestRefFromDictionary:(NSDictionary *)dict;

- (instancetype) initWithName:(NSString *)name;
- (instancetype) initWithName:(NSString *)name
                     inverted:(BOOL)inverted NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, getter=isInverted, readonly) BOOL inverted;

/* Returns a dictionary that represents the object. It can be used for storing the object to
 * preferences.
 */
- (NSDictionary *)dictionaryForObject;

@end
