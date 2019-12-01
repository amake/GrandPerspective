#import <Cocoa/Cocoa.h>


@class AnnotatedTreeContext;

@interface WriteTaskInput : NSObject {
}

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path;
- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path
                                      options:(id)options NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) AnnotatedTreeContext *annotatedTreeContext;
@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly, strong) id options;

@end
