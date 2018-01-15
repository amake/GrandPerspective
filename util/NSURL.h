#import <Foundation/Foundation.h>

@interface NSURL (HelperMethods)
- (BOOL) isDirectory;
- (BOOL) isPackage;
- (BOOL) isHardLinked;
- (CFAbsoluteTime) creationTime;
- (CFAbsoluteTime) modificationTime;
- (CFAbsoluteTime) accessTime;
@end
