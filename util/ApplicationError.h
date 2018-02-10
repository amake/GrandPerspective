#import <Cocoa/Cocoa.h>


/* Error that signals recoverable errors at the application level, e.g. failure to open a file. It
 * is not intended for critical errors, e.g. assertion failures due to bugs.
 */
@interface ApplicationError : NSError {

}

- (instancetype) initWithLocalizedDescription:(NSString *)descr;
- (instancetype) initWithCode:(int)code localizedDescription:(NSString *)descr;
- (instancetype) initWithCode:(int)code userInfo:(NSDictionary *)userInfo NS_DESIGNATED_INITIALIZER;

+ (instancetype) errorWithLocalizedDescription:(NSString *)descr;
+ (instancetype) errorWithCode:(int)code localizedDescription:(NSString *)descr;
+ (instancetype) errorWithCode:(int)code userInfo:(NSDictionary *)userInfo;

@end
