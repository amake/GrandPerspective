#import <Cocoa/Cocoa.h>


@class FileItemTest;

@interface FilterTest : NSObject {
}

+ (instancetype) filterTestWithName:(NSString *)name fileItemTest:(FileItemTest *)test;

- (instancetype) initWithName:(NSString *)name
                 fileItemTest:(FileItemTest *)test NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, strong) FileItemTest *fileItemTest;

@end
