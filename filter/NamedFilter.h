#import <Cocoa/Cocoa.h>


@class Filter;

@interface NamedFilter : NSObject {
  Filter  *filter;
  NSString  *name;
}

+ (NamedFilter *)emptyFilterWithName:(NSString *)name;
+ (NamedFilter *)namedFilter:(Filter *)filter name:(NSString *)name;

- (instancetype) initWithFilter:(Filter *)filter
                           name:(NSString *)name NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) Filter *filter;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *localizedName;

@end
