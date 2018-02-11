#import <Cocoa/Cocoa.h>


@class TreeContext;


/* A tree context with additional text comments that allow human-readable information to be
 * associated with the scan data. The comments can be used by the application to document the use of
 * a filter, but also for the user to provide further background information with respect to the
 * scan, e.g. "My harddrive just before upgrading to Snow Leopard".
 */
@interface AnnotatedTreeContext : NSObject {
}

+ (instancetype) annotatedTreeContext:(TreeContext *)treeContext;
+ (instancetype) annotatedTreeContext:(TreeContext *)treeContext
                             comments:(NSString *)comments;

- (instancetype) initWithTreeContext:(TreeContext *)treeContext;
- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                            comments:(NSString *)comments NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) TreeContext *treeContext;
@property (nonatomic, readonly, copy) NSString *comments;

@end
