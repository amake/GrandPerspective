#import <Cocoa/Cocoa.h>


@interface DirectoryViewControlSettings : NSObject {
}

- (instancetype) initWithColorMappingKey:(NSString *)colorMappingKey
                         colorPaletteKey:(NSString *)colorPaletteKey
                                maskName:(NSString *)maskName
                             maskEnabled:(BOOL)maskEnabled
                        showEntireVolume:(BOOL)showEntireVolume
                     showPackageContents:(BOOL)showPackageContents
                        unzoomedViewSize:(NSSize)viewSize NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) NSString *colorMappingKey;

@property (nonatomic, copy) NSString *colorPaletteKey;

@property (nonatomic, copy) NSString *maskName;

@property (nonatomic) BOOL fileItemMaskEnabled;

@property (nonatomic) BOOL showEntireVolume;

@property (nonatomic) BOOL showPackageContents;

/* The window's size when it is unzoomed. This is considered its real size setting. When the
 * window is zoomed, the maximum size is only a temporary state.
 */
@property (nonatomic) NSSize unzoomedViewSize;

@end
