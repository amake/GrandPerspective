#import <Cocoa/Cocoa.h>


@interface ReadTaskInput : NSObject {
}

- (instancetype) initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *path;

@end
