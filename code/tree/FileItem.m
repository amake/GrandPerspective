#import "FileItem.h"

#import "DirectoryItem.h"
#import "PreferencesPanelControl.h"


NSString*  FileSizeBase2 = @"base-2";
NSString*  FileSizeBase10 = @"base-10";

@interface FileItem (PrivateMethods)

+ (NSString *)filesizeUnitString:(int) order;
+ (NSString *)decimalSeparator;

+ (CFDateFormatterRef) timeFormatter;

- (NSString *)constructPath:(BOOL) useFileSystemRepresentation;

@end


@implementation FileItem

+ (NSArray *) fileSizeMeasureBaseNames {
  static NSArray  *fileSizeMeasureBaseNames = nil;
  
  if (fileSizeMeasureBaseNames == nil) {
    fileSizeMeasureBaseNames = 
    [[NSArray arrayWithObjects: FileSizeBase2, FileSizeBase10, nil] 
     retain];
  }
  
  return fileSizeMeasureBaseNames;
}

// Overrides super's designated initialiser.
- (id) initWithItemSize:(ITEM_SIZE) sizeVal {
  return [self initWithName: @"" 
                     parent: nil 
                       size: sizeVal
                      flags: 0 
               creationTime: 0 
           modificationTime: 0
                 accessTime: 0];
}


- (id) initWithName: (NSString *)nameVal 
             parent: (DirectoryItem *)parentVal
               size: (ITEM_SIZE) sizeVal 
              flags: (UInt8) flagsVal
       creationTime: (CFAbsoluteTime) creationTimeVal
   modificationTime: (CFAbsoluteTime) modificationTimeVal
         accessTime: (CFAbsoluteTime) accessTimeVal {
  if (self = [super initWithItemSize: sizeVal]) {
    name = [nameVal retain];

    parent = parentVal; // not retaining it, as it is not owned.
    flags = flagsVal;
    
    creationTime = creationTimeVal;
    modificationTime = modificationTimeVal;
    accessTime = accessTimeVal;
  }
  return self;
}
  
- (void) dealloc {
  if (parent==nil) {
    NSLog(@"FileItem-dealloc (root)");
  }
  [name release];

  [super dealloc];
}


- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  NSAssert(NO, @"-duplicateFileItem: called on (abstract) FileItem.");
}


- (NSString *)description {
  return [NSString stringWithFormat:@"FileItem(%@, %qu)", name, size];
}


- (FILE_COUNT) numFiles {
  return 1;
}

- (NSString *)name {
  return name;
}

- (DirectoryItem *)parentDirectory {
  return parent;
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


- (CFAbsoluteTime) creationTime {
  return creationTime;
}

- (CFAbsoluteTime) modificationTime {
  return modificationTime;
}

- (CFAbsoluteTime) accessTime {
  return accessTime;
}


- (UInt8) fileItemFlags {
  return flags;
}

- (BOOL) isPhysical {
  return (flags & FILE_IS_NOT_PHYSICAL) == 0;
}

- (BOOL) isHardLinked {
  return (flags & FILE_IS_HARDLINKED) != 0;
}

- (BOOL) isPackage {
  return (flags & FILE_IS_PACKAGE) != 0;
}


- (NSString *)pathComponent {
  // Only physical items contribute to the path.
  return [self isPhysical] ? name : nil;
}

- (NSString *)path {
  return [self constructPath: NO];
}

- (NSString *)systemPath {
  return [self constructPath: YES];
}


+ (NSString *)stringForFileItemSize:(ITEM_SIZE) filesize {
  NSString*  fileSizeMeasureBase =
    [[NSUserDefaults standardUserDefaults] stringForKey: FileSizeMeasureBaseKey];
  int  bytesLimit = 1024;
  if ([fileSizeMeasureBase isEqualToString: FileSizeBase10]) {
    bytesLimit = 1000;
  }
  
  if (filesize < bytesLimit) {
    // Definitely don't want a decimal point here
    NSString  *byteSizeUnit = NSLocalizedString( @"B", 
                                                 @"File size unit for bytes." );
    return [NSString stringWithFormat:@"%qu %@", filesize, byteSizeUnit];
  }

  double  n = (double)filesize / bytesLimit;
  int  m = 0;
  // Note: The threshold for "n" is chosen to cope with rounding, ensuring
  // that the string for n = 1024^3 becomes "1.00 GB" instead of "1024 MB"
  while (n > (bytesLimit - 0.001) && m < 3) {
    m++;
    n /= bytesLimit; 
  }

  NSMutableString*  s = 
    [[[NSMutableString alloc] initWithCapacity:12] autorelease];
  [s appendFormat:@"%.2f", n];
  
  // Ensure that only the three most-significant digits are shown.
  // Exception: If there are four digits before the decimal point, all four
  // are shown.
  
  NSRange  dotRange = [s rangeOfString: @"."];
  if (dotRange.location != NSNotFound) {
    int  delPos = ((dotRange.location < 3) ?
                   4 : // Keep one or more digits after the decimal point.
                   dotRange.location);
                       // Keep only the digits before the decimal point.

    [s deleteCharactersInRange:NSMakeRange(delPos, [s length] - delPos)];
    
    if (dotRange.location < delPos) {
      // The dot is still visible, so localize it
      
      [s replaceCharactersInRange: dotRange withString: 
           [FileItem decimalSeparator]];
    }
  }
  else {
    // Void. We always expect a dot (even if the user has set a different
    // decimal separator in his I18N settings). So this should not really
    // happen, but raise no fuss if it does anyway.
  }

  [s appendFormat:@" %@", [FileItem filesizeUnitString: m] ];

  return s;
}


+ (NSString *)exactStringForFileItemSize:(ITEM_SIZE) filesize {
  NSString  *format = NSLocalizedString( @"%qu bytes", 
                                         @"Exact file size (in bytes)." );

  return [NSString stringWithFormat: format, filesize ];
}


+ (NSString *)stringForTime:(CFAbsoluteTime) absTime {
  if (absTime == 0) {
    return @"";
  } else {
    return [(NSString *)CFDateFormatterCreateStringWithAbsoluteTime(NULL,
                                                                   [self timeFormatter],
                                                                   absTime)
            autorelease];
  }
}

@end // @implementation FileItem


@implementation FileItem (ProtectedMethods)

- (NSString *)systemPathComponent {
  if (! [self isPhysical] ) {
    return nil;
  }
  NSMutableString  *comp = [NSMutableString stringWithString: name];

  [comp replaceOccurrencesOfString: @"/" withString: @":"
          options: NSLiteralSearch range: NSMakeRange(0, [comp length])];
  return comp;
}
    
@end // @implementation FileItem (ProtectedMethods)


@implementation FileItem (PrivateMethods)

+ (NSString *)filesizeUnitString:(int) order {
  switch (order) {
    case 0: return NSLocalizedString( @"kB", @"File size unit for kilobytes.");
    case 1: return NSLocalizedString( @"MB", @"File size unit for megabytes.");
    case 2: return NSLocalizedString( @"GB", @"File size unit for gigabytes.");
    case 3: return NSLocalizedString( @"TB", @"File size unit for terabytes.");
    default: return @""; // Should not happen, but cannot can NSAssert here.
  }
}


+ (NSString *)decimalSeparator {
  static NSString  *decimalSeparator = nil;

  if (decimalSeparator == nil) {
    NSNumberFormatter  *numFormat = 
      [[NSNumberFormatter alloc] init];
    [numFormat setLocalizesFormat: YES];
    decimalSeparator = [[numFormat decimalSeparator] retain];
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
  NSString  *comp = 
    ( useFileSystemRepresentation 
      ? [self systemPathComponent] 
      : [self pathComponent] );
  
  if (comp != nil) {
    return ( (parent != nil) 
             ? [[parent constructPath: useFileSystemRepresentation] 
                   stringByAppendingPathComponent: comp] 
             : comp );
  }
  else {
    return ( (parent != nil) 
             ? [parent constructPath: useFileSystemRepresentation] 
             : @"" );
  }
}

@end // @implementation FileItem (PrivateMethods)
