#import <Cocoa/Cocoa.h>

@class FileItem;
@class TreeLayoutBuilder;

@interface DrawTaskInput : NSObject {
}

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) FileItem *visibleTree;
@property (nonatomic, readonly, strong) FileItem *treeInView;
@property (nonatomic, readonly, strong) TreeLayoutBuilder *layoutBuilder;
@property (nonatomic, readonly) NSRect bounds;

@end
