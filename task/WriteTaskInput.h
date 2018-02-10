#import <Cocoa/Cocoa.h>


@class AnnotatedTreeContext;

@interface WriteTaskInput : NSObject {
  AnnotatedTreeContext  *treeContext;
  NSString  *path;
}

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) AnnotatedTreeContext *annotatedTreeContext;
@property (nonatomic, readonly, copy) NSString *path;

@end
