#import "ApplicationError.h"


@implementation ApplicationError

// Overrides designated initialiser
- (instancetype) initWithDomain:(NSString *)domain
                           code:(NSInteger)code
                       userInfo:(NSDictionary *)userInfo {
  NSAssert(NO, @"Use initWithCode:userInfo instead.");
  return nil;
}

- (instancetype) initWithLocalizedDescription:(NSString *)descr {
  return [self initWithCode: -1 localizedDescription: descr];
}

- (instancetype) initWithCode:(int)code localizedDescription:(NSString *)descr {
  return [self initWithCode: code
                   userInfo: @{NSLocalizedDescriptionKey: descr}];
}

- (instancetype) initWithCode:(int)code userInfo:(NSDictionary *)userInfo {
  return [super initWithDomain: @"Application" code: code userInfo: userInfo];
}

+ (instancetype) errorWithLocalizedDescription:(NSString *)descr {
  return [[[ApplicationError alloc] initWithLocalizedDescription: descr] autorelease];
}

+ (instancetype) errorWithCode:(int)code localizedDescription:(NSString *)descr {
  return [[[ApplicationError alloc] initWithCode: code localizedDescription: descr] autorelease];
}

+ (instancetype) errorWithCode:(int)code userInfo:(NSDictionary *)userInfo {
  return [[[ApplicationError alloc] initWithCode: code userInfo: userInfo] autorelease];
}

@end
