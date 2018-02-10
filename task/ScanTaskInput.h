#import <Cocoa/Cocoa.h>

@class FilterSet;


@interface ScanTaskInput : NSObject {
  BOOL  packagesAsFiles;
  NSString  *pathToScan;
  NSString  *fileSizeMeasure;
  FilterSet  *filterSet;
}

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)measure
                    filterSet:(FilterSet *)filterSet;

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)measure
                    filterSet:(FilterSet *)filterSet
              packagesAsFiles:(BOOL) packagesAsFiles NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *pathToScan;
@property (nonatomic, readonly, copy) NSString *fileSizeMeasure;
@property (nonatomic, readonly, strong) FilterSet *filterSet;
@property (nonatomic, readonly) BOOL packagesAsFiles;

@end
