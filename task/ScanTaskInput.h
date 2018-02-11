#import <Cocoa/Cocoa.h>

@class FilterSet;


@interface ScanTaskInput : NSObject {
}

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)measure
                    filterSet:(FilterSet *)filterSet;

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)measure
                    filterSet:(FilterSet *)filterSet
              packagesAsFiles:(BOOL) packagesAsFiles NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly, copy) NSString *fileSizeMeasure;
@property (nonatomic, readonly, strong) FilterSet *filterSet;
@property (nonatomic, readonly) BOOL packagesAsFiles;

@end
