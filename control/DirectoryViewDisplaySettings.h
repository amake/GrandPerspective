#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DirectoryViewDisplaySettings : NSObject<NSCopying>

- (instancetype) initWithColorMappingKey:(NSString *)colorMappingKey
                         colorPaletteKey:(NSString *)colorPaletteKey
                                maskName:(NSString *)maskName
                             maskEnabled:(BOOL)maskEnabled
                        showEntireVolume:(BOOL)showEntireVolume
                     showPackageContents:(BOOL)showPackageContents NS_DESIGNATED_INITIALIZER;

+ (DirectoryViewDisplaySettings *)defaultSettings;

@property (nonatomic, copy) NSString *colorMappingKey;

@property (nonatomic, copy) NSString *colorPaletteKey;

@property (nonatomic, copy, nullable) NSString *maskName;

@property (nonatomic) BOOL fileItemMaskEnabled;

@property (nonatomic) BOOL showEntireVolume;

@property (nonatomic) BOOL showPackageContents;

@end

NS_ASSUME_NONNULL_END
