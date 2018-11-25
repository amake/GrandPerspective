#import <Foundation/Foundation.h>

@class TreeContext;

@interface ScanTaskOutput : NSObject {
}

+ (instancetype) scanTaskOutput:(TreeContext *)treeContext alert:(NSAlert *)alert;

- (instancetype) initWithTreeContext:(TreeContext *)treeContext alert:(NSAlert *)alert;

@property (nonatomic, readonly, strong) TreeContext *treeContext;
@property (nonatomic, readonly, strong) NSAlert *alert;

@end
