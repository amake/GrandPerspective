#import <Foundation/Foundation.h>



@interface NSURL (HelperMethods)

@property (nonatomic, getter=isDirectory, readonly) BOOL directory;
@property (nonatomic, getter=isPackage, readonly) BOOL package;
@property (nonatomic, getter=isHardLinked, readonly) BOOL hardLinked;
@property (nonatomic, readonly) CFAbsoluteTime creationTime;
@property (nonatomic, readonly) CFAbsoluteTime modificationTime;
@property (nonatomic, readonly) CFAbsoluteTime accessTime;

- (void) getParentURL:(out NSURL* _Nullable *_Nonnull)parentURL;

+ (NSArray *_Nonnull)supportedPasteboardTypes;
+ (NSURL *_Nullable)getFileURLFromPasteboard:(NSPasteboard *_Nonnull)pboard;

@end
