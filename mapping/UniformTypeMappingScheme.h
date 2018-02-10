#import <Cocoa/Cocoa.h>

#import "FileItemMappingScheme.h"


@class UniformTypeRanking;

@interface UniformTypeMappingScheme : NSObject <FileItemMappingScheme> {

  UniformTypeRanking  *typeRanking;

}

- (instancetype) initWithUniformTypeRanking:(UniformTypeRanking *)typeRanking NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) UniformTypeRanking *uniformTypeRanking;

@end
