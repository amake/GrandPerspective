#import "ScanTreeRoot.h"

@implementation ScanTreeRoot

- (void) dealloc {
  NSLog(@"ScanTreeRoot-dealloc (root)");
  NSZone  *zone = [self zone];

  [super dealloc];

  if ([Item disposeZoneAfterUse: zone]) {
    NSLog(@"Recyling memory zone");
    NSRecycleZone(zone);
    NSLog(@"Recycled memory zone");
  }
}

@end // @implementation ScanTreeRoot
