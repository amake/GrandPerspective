#import <AvailabilityMacros.h>

#ifdef MAC_OS_X_VERSION_MAX_ALLOWED
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1060

// Dummy protocols for protocols introduced in SDK 10.6 so that the code can
// compile with older SDKs.

@protocol NSTableViewDataSource
@end

@protocol NSTableViewDelegate
@end

@protocol NSXMLParserDelegate
@end

@protocol NSWindowDelegate
@end

@protocol NSToolbarDelegate
@end

#endif
#endif