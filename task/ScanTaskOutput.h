#import <Foundation/Foundation.h>

@class AlertMessage;
@class TreeContext;

@interface ScanTaskOutput : NSObject {
}

+ (instancetype) scanTaskOutput:(TreeContext *)treeContext alert:(AlertMessage *)alert;
+ (instancetype) failedScanTaskOutput:(AlertMessage *)alert;

- (instancetype) initWithTreeContext:(TreeContext *)treeContext alert:(AlertMessage *)alert;

@property (nonatomic, readonly, strong) TreeContext *treeContext;
@property (nonatomic, readonly, strong) AlertMessage *alert;

@end
