#import "FileItem.h"

#import "DirectoryItem.h"
#import "PreferencesPanelControl.h"


NSString*  FileSizeUnitSystemBase2 = @"base-2";
NSString*  FileSizeUnitSystemBase10 = @"base-10";

@interface FileItem (PrivateMethods)

+ (NSString *)filesizeUnitString:(int)order;
+ (NSString *)decimalSeparator;

+ (CFDateFormatterRef) timeFormatter;

- (NSString *)constructPath:(BOOL)useFileSystemRepresentation;

@end


@implementation FileItem

+ (NSArray *) fileSizeUnitSystemNames {
  static NSArray  *fileSizeMeasureBaseNames = nil;
  
  if (fileSizeMeasureBaseNames == nil) {
    fileSizeMeasureBaseNames = [@[FileSizeUnitSystemBase2, FileSizeUnitSystemBase10] retain];
  }
  
  return fileSizeMeasureBaseNames;
}

+ (int) bytesPerKilobyte {
  NSString*  fileSizeMeasureBase =
    [[NSUserDefaults standardUserDefaults] stringForKey: FileSizeUnitSystemKey];

  if ([fileSizeMeasureBase isEqualToString: FileSizeUnitSystemBase10]) {
    return 1000;
  } else {
    // Assume binary (also when value is unrecognized/invalid)
    return 1024;
  }
}

// Overrides super's designated initialiser.
- (instancetype) initWithItemSize:(ITEM_SIZE) sizeVal {
  return [self initWithLabel: @""
                      parent: nil
                        size: sizeVal
                       flags: 0
                creationTime: 0
            modificationTime: 0
                  accessTime: 0];
}


- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(ITEM_SIZE)size
                         flags:(UInt8)fileItemFlags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  if (self = [super initWithItemSize: size]) {
    _label = [label retain];

    _parentDirectory = parent; // not retaining it, as it is not owned.
    _fileItemFlags = fileItemFlags;
    
    _creationTime = creationTime;
    _modificationTime = modificationTime;
    _accessTime = accessTime;
  }
  return self;
}
  
- (void) dealloc {
  if (_parentDirectory==nil) {
    NSLog(@"FileItem-dealloc (root)");
  }
  [_label release];

  [super dealloc];
}

- (DirectoryItem *)parentDirectory {
  return _parentDirectory;
}


- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  NSAssert(NO, @"-duplicateFileItem: called on (abstract) FileItem.");
  return nil;
}


- (NSString *)description {
  return [NSString stringWithFormat:@"FileItem(%@, %qu)", self.label, self.itemSize];
}


- (FILE_COUNT) numFiles {
  return 1;
}

- (BOOL) isAncestorOfFileItem:(FileItem *)fileItem {
  do {
    if (fileItem == self) {
      return YES;
    }
    fileItem = [fileItem parentDirectory];
  } while (fileItem != nil);
  
  return NO;
}


- (BOOL) isDirectory {
  return NO;
}


- (BOOL) isPhysical {
  return (self.fileItemFlags & FILE_IS_NOT_PHYSICAL) == 0;
}

- (BOOL) isHardLinked {
  return (self.fileItemFlags & FILE_IS_HARDLINKED) != 0;
}

- (BOOL) isPackage {
  return (self.fileItemFlags & FILE_IS_PACKAGE) != 0;
}


- (NSString *)pathComponent {
  if (! [self isPhysical] ) {
    return nil;
  }

  return [FileItem friendlyPathComponentFor: self.label];
}

- (NSString *)path {
  return [self constructPath: NO];
}

- (NSString *)systemPath {
  return [self constructPath: YES];
}


+ (NSString *)stringForFileItemSize:(ITEM_SIZE)filesize {
  int  bytesUnit = [FileItem bytesPerKilobyte];
  
  if (filesize < bytesUnit) {
    // Definitely don't want a decimal point here
    NSString  *byteSizeUnit = NSLocalizedString(@"B", @"File size unit for bytes.");
    return [NSString stringWithFormat:@"%qu %@", filesize, byteSizeUnit];
  }

  double  n = (double)filesize / bytesUnit;
  int  m = 0;
  // Note: The threshold for "n" is chosen to cope with rounding, ensuring that the string for
  // n = 1024^3 becomes "1.00 GB" instead of "1024 MB"
  while (n > (bytesUnit - 0.001) && m < 3) {
    m++;
    n /= bytesUnit; 
  }

  NSMutableString*  s = [[[NSMutableString alloc] initWithCapacity:12] autorelease];
  [s appendFormat:@"%.2f", n];
  
  // Ensure that only the three most-significant digits are shown.
  // Exception: If there are four digits before the decimal point, all four are shown.
  
  NSRange  dotRange = [s rangeOfString: @"."];
  if (dotRange.location != NSNotFound) {
    NSUInteger  delPos = (
      (dotRange.location < 3) ?
      4 :               // Keep one or more digits after the decimal point.
      dotRange.location // Keep only the digits before the decimal point.
    );

    [s deleteCharactersInRange:NSMakeRange(delPos, s.length - delPos)];
    
    if (dotRange.location < delPos) {
      // The dot is still visible, so localize it
      
      [s replaceCharactersInRange: dotRange withString: [FileItem decimalSeparator]];
    }
  }
  else {
    // Void. We always expect a dot (even if the user has set a different decimal separator in his
    // I18N settings). So this should not really happen, but raise no fuss if it does anyway.
  }

  [s appendFormat:@" %@", [FileItem filesizeUnitString: m]];

  return s;
}


+ (NSString *)exactStringForFileItemSize:(ITEM_SIZE)filesize {
  NSString  *format = NSLocalizedString(@"%qu bytes", @"Exact file size (in bytes).");

  return [NSString stringWithFormat: format, filesize ];
}


+ (NSString *)stringForTime:(CFAbsoluteTime)absTime {
  if (absTime == 0) {
    return @"";
  } else {
    return [(NSString *)CFDateFormatterCreateStringWithAbsoluteTime(NULL,
                                                                    [self timeFormatter],
                                                                    absTime)
            autorelease];
  }
}

/* Returns path component as it is displayed to user, with colons replaced by slashes.
 */
+ (NSString *)friendlyPathComponentFor:(NSString *)pathComponent {
  NSMutableString  *comp = [NSMutableString stringWithString: pathComponent];
  [comp replaceOccurrencesOfString: @":"
                        withString: @"/"
                           options: NSLiteralSearch
                             range: NSMakeRange(0, comp.length)];
  return comp;
}

/* Returns path component as it is used by system, with slashes replaced by colons.
 */
+ (NSString *)systemPathComponentFor:(NSString *)pathComponent {
  NSMutableString  *comp = [NSMutableString stringWithString: pathComponent];
  [comp replaceOccurrencesOfString: @"/"
                        withString: @":"
                           options: NSLiteralSearch
                             range: NSMakeRange(0, comp.length)];
  return comp;
}

@end // @implementation FileItem


@implementation FileItem (ProtectedMethods)

- (NSString *)systemPathComponent {
  // Only physical items contribute to the path.
  return [self isPhysical] ? self.label : nil;
}
    
@end // @implementation FileItem (ProtectedMethods)


@implementation FileItem (PrivateMethods)

+ (NSString *)filesizeUnitString:(int)order {
  switch (order) {
    case 0: return NSLocalizedString(@"kB", @"File size unit for kilobytes.");
    case 1: return NSLocalizedString(@"MB", @"File size unit for megabytes.");
    case 2: return NSLocalizedString(@"GB", @"File size unit for gigabytes.");
    case 3: return NSLocalizedString(@"TB", @"File size unit for terabytes.");
    default: NSAssert(NO, @"Unexpected order value"); return @"";
  }
}


+ (NSString *)decimalSeparator {
  static NSString  *decimalSeparator = nil;

  if (decimalSeparator == nil) {
    NSNumberFormatter  *numFormat = [[[NSNumberFormatter alloc] init] autorelease];
    [numFormat setLocalizesFormat: YES];
    decimalSeparator = [numFormat.decimalSeparator retain];
  }

  return decimalSeparator;
}


+ (CFDateFormatterRef) timeFormatter {
  static CFDateFormatterRef dateFormatter = NULL;
  
  if (dateFormatter == NULL) {
    // Lazily create formatter
    dateFormatter = CFDateFormatterCreate(NULL, NULL, 
                                          kCFDateFormatterShortStyle, 
                                          kCFDateFormatterShortStyle);    
  }
  
  return dateFormatter;
}


- (NSString *)constructPath:(BOOL) useFileSystemRepresentation {
  NSString  *comp = useFileSystemRepresentation ? [self systemPathComponent] : [self pathComponent];
  
  if (comp != nil) {
    return ( (self.parentDirectory != nil)
             ? [[self.parentDirectory constructPath: useFileSystemRepresentation]
                  stringByAppendingPathComponent: comp] 
             : comp );
  }
  else {
    return ( (self.parentDirectory != nil)
             ? [self.parentDirectory constructPath: useFileSystemRepresentation]
             : @"" );
  }
}

@end // @implementation FileItem (PrivateMethods)
