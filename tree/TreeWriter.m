#import "TreeWriter.h"

#import "TreeVisitingProgressTracker.h"

// Formatting string used in XML (RFC 3339)
NSString  *DateTimeFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

@implementation TreeWriter

- (instancetype) init {
  if (self = [super init]) {
    abort = NO;
    error = nil;

    progressTracker = [[TreeVisitingProgressTracker alloc] init];
  }
  return self;
}

- (void) dealloc {
  [error release];

  [progressTracker release];

  [super dealloc];
}

- (BOOL) writeTree:(AnnotatedTreeContext *)tree toFile:(NSString *)path {
  NSAssert(NO, @"This method should be overridden.");
  return NO;
}

- (void) abort {
  abort = YES;
}

- (BOOL) aborted {
  return (error==nil) && abort;
}

- (NSError *)error {
  return error;
}

- (NSDictionary *)progressInfo {
  return [progressTracker progressInfo];
}

@end


@implementation TreeWriter (ProtectedMethods)

+ (CFDateFormatterRef) timeFormatter {
  static CFDateFormatterRef dateFormatter = NULL;

  if (dateFormatter == NULL) {
    // Lazily create formatter
    dateFormatter = CFDateFormatterCreate(kCFAllocatorDefault,
                                          NULL,
                                          kCFDateFormatterNoStyle,
                                          kCFDateFormatterNoStyle);
    // Fix the format so that output is locale independent.
    // Was originally "en_GB" locale, but in OS X 10.11 this went from
    //   dd/MM/yyyy HH:mm
    // to
    //   dd/MM/yyyy, HH:mm
    // which broke parsing saved scans in some situations and also left out
    // timezone information. We now use a safer representation.
    CFDateFormatterSetFormat(dateFormatter, (CFStringRef)DateTimeFormat);
  }

  return dateFormatter;
}

+ (NSDateFormatter *)nsTimeFormatter {
  static NSDateFormatter *timeFmt = nil;
  if (timeFmt == nil) {
    timeFmt = [[NSDateFormatter alloc] init];
    timeFmt.locale = [NSLocale localeWithLocaleIdentifier: @"en_US_POSIX"];
    timeFmt.dateFormat = DateTimeFormat;
    timeFmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
  }
  return timeFmt;
}

+ (NSString *)stringForTime:(CFAbsoluteTime)time {
  if (time == 0) {
    return nil;
  } else {
    return
    [(NSString *)CFDateFormatterCreateStringWithAbsoluteTime(NULL, [self timeFormatter], time)
     autorelease];
  }
}

@end
