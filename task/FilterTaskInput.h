#import <Cocoa/Cocoa.h>

@class TreeContext;
@class FilterSet;


@interface FilterTaskInput : NSObject {
}

- (instancetype) initWithTreeContext:(TreeContext *)context
                           filterSet:(FilterSet *)filterSet;

- (instancetype) initWithTreeContext:(TreeContext *)context
                           filterSet:(FilterSet *)test
                     packagesAsFiles:(BOOL) packagesAsFiles NS_DESIGNATED_INITIALIZER;


@property (nonatomic, readonly, strong) TreeContext *treeContext;
@property (nonatomic, readonly, strong) FilterSet *filterSet;
@property (nonatomic, readonly) BOOL packagesAsFiles;

@end
