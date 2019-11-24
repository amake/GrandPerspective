#import "XmlTreeWriter.h"

#import "DirectoryItem.h"

#import "TreeContext.h"
#import "AnnotatedTreeContext.h"

#import "FilterTestRef.h"
#import "Filter.h"
#import "NamedFilter.h"
#import "FilterSet.h"

#import "TreeVisitingProgressTracker.h"


#define  AUTORELEASE_PERIOD  1024

/* Changes
 * v6: Use system path component for name of physical files and directories
 */
NSString  *TreeWriterFormatVersion = @"6";

// XML elements
NSString  *ScanDumpElem = @"GrandPerspectiveScanDump";
NSString  *ScanInfoElem = @"ScanInfo";
NSString  *ScanCommentsElem = @"ScanComments";
NSString  *FilterSetElem = @"FilterSet";
NSString  *FilterElem = @"Filter";
NSString  *FilterTestElem = @"FilterTest";
NSString  *FolderElem = @"Folder";
NSString  *FileElem = @"File";

// XML attributes of GrandPerspectiveScanDump
NSString  *AppVersionAttr = @"appVersion";
NSString  *FormatVersionAttr = @"formatVersion";

// XML attributes of GrandPerspectiveScanInfo
NSString  *VolumePathAttr = @"volumePath";
NSString  *VolumeSizeAttr = @"volumeSize";
NSString  *FreeSpaceAttr = @"freeSpace";
NSString  *ScanTimeAttr = @"scanTime";
NSString  *FileSizeMeasureAttr = @"fileSizeMeasure";

// XML attributes of FilterTest
NSString  *InvertedAttr = @"inverted";

// XML attributes of Folder and File
NSString  *NameAttr = @"name";
NSString  *FlagsAttr = @"flags";
NSString  *SizeAttr = @"size";
NSString  *CreatedAttr = @"created";
NSString  *ModifiedAttr = @"modified";
NSString  *AccessedAttr = @"accessed";

// XML attribute values
NSString  *TrueValue = @"true";
NSString  *FalseValue = @"false";

typedef NS_OPTIONS(NSUInteger, CharacterOptions) {
  CharAmpersand = 0x01,
  CharLessThan = 0x02,
  CharDoubleQuote = 0x04,
  CharWhitespace = 0x08,
  // All non-printing ASCII characters (this excludes whitespace)
  CharNonPrinting = 0x10
};

#define  ATTRIBUTE_ESCAPE_CHARS \
(CharAmpersand | CharLessThan | CharDoubleQuote | CharWhitespace | CharNonPrinting)
#define  CHARDATA_ESCAPE_CHARS \
(CharAmpersand | CharLessThan | CharNonPrinting)


/* Escapes the string so that it can be used a valid XML attribute value or valid XML character
 * data. The characters that are escaped are specified by a mask, which must reflect the context
 * where the string is to be used.
 */
NSString *escapedXML(NSString *s, CharacterOptions escapeCharMask) {
  // Lazily construct buffer. Only use it when needed.
  NSMutableString  *buf = nil;

  NSUInteger  i;
  NSUInteger  numCharsInVal = s.length;
  NSUInteger  numCharsInBuf = 0;

  for (i = 0; i < numCharsInVal; i++) {
    unichar  c = [s characterAtIndex: i];
    NSString  *r = nil;
    if (c == '&' && (escapeCharMask & CharAmpersand) != 0) {
      r = @"&amp;";
    }
    else if (c == '<' && (escapeCharMask & CharLessThan) != 0) {
      r = @"&lt;";
    }
    else if (c == '"' && (escapeCharMask & CharDoubleQuote) != 0) {
      r = @"&quot;";
    }
    else if (c < 0x20) {
      if (c == 0x09 || c == 0x0a || c == 0x0d) {
        // White space
        if ((escapeCharMask & CharWhitespace) != 0) {
          r = @" ";
        }
      } else {
        if ((escapeCharMask & CharNonPrinting) != 0) {
          // Some files can have names with non-printing characters. Just do something to ensure
          // that the XML data can be loaded correctly. However, no attempt is made to enable a
          // reversible transformation. Such names should be discouraged not supported.
          r = @"?";
        }
      }
    }
    if (r != nil) {
      if (buf == nil) {
        buf = [NSMutableString stringWithCapacity: numCharsInVal * 2];
      }

      if (numCharsInBuf < i) {
        // Copy preceding characters that did not require escaping to buffer
        [buf appendString: [s substringWithRange: NSMakeRange(numCharsInBuf, i - numCharsInBuf)]];
        numCharsInBuf = i;
      }

      [buf appendString: r];
      numCharsInBuf++;
    }
  }

  if (buf == nil) {
    // String did not contain an characters that needed escaping
    return s;
  }

  if (numCharsInBuf < numCharsInVal) {
    // Append final characters to buffer
    [buf appendString: [s substringWithRange:
                        NSMakeRange(numCharsInBuf, numCharsInVal - numCharsInBuf)]];
    numCharsInBuf = numCharsInVal;
  }

  return buf;
}


@interface XmlTreeWriter (PrivateMethods)

- (void) appendScanDumpElement:(AnnotatedTreeContext *)tree;
- (void) appendScanInfoElement:(AnnotatedTreeContext *)tree;
- (void) appendScanCommentsElement:(NSString *)comments;
- (void) appendFilterSetElement:(FilterSet *)filterSet;
- (void) appendFilterElement:(NamedFilter *)filter;
- (void) appendFilterTestElement:(FilterTestRef *)filterTest;

@end


@implementation XmlTreeWriter

- (instancetype) init {
  if (self = [super init]) {
    autoreleasePool = nil;
  }
  return self;
}

- (void) dealloc {
  NSAssert(autoreleasePool == nil, @"autoreleasePool should be nil");

  [super dealloc];
}

- (void) writeTree:(AnnotatedTreeContext *)tree {
  [self appendString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
  [self appendScanDumpElement: tree];

  [autoreleasePool release];
  autoreleasePool = nil;
}

@end

@implementation XmlTreeWriter (PrivateMethods)

- (void) appendScanDumpElement:(AnnotatedTreeContext *)annotatedTree {
  NSString  *appVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];

  [self appendString:
   [NSString stringWithFormat: @"<%@ %@=\"%@\" %@=\"%@\">\n",
    ScanDumpElem,
    AppVersionAttr, appVersion,
    FormatVersionAttr, TreeWriterFormatVersion]];

  [self appendScanInfoElement: annotatedTree];

  [self appendString: [NSString stringWithFormat: @"</%@>\n", ScanDumpElem]];
}


- (void) appendScanInfoElement:(AnnotatedTreeContext *)annotatedTree {
  TreeContext  *tree = [annotatedTree treeContext];

  [self appendString:
   [NSString stringWithFormat:
    @"<%@ %@=\"%@\" %@=\"%qu\" %@=\"%qu\" %@=\"%@\" %@=\"%@\">\n",
    ScanInfoElem,
    VolumePathAttr, escapedXML( [[tree volumeTree] systemPathComponent],
                               ATTRIBUTE_ESCAPE_CHARS ),
    VolumeSizeAttr, [tree volumeSize],
    FreeSpaceAttr, ([tree freeSpace] + [tree freedSpace]),
    ScanTimeAttr, [[TreeWriter nsTimeFormatter] stringFromDate:[tree scanTime]],
    FileSizeMeasureAttr, [tree fileSizeMeasure]]];

  [self appendScanCommentsElement: [annotatedTree comments]];
  [self appendFilterSetElement: [tree filterSet]];

  [tree obtainReadLock];
  [self appendFolderElement: [tree scanTree]];
  [tree releaseReadLock];

  [self appendString: [NSString stringWithFormat: @"</%@>\n", ScanInfoElem]];
}


- (void) appendScanCommentsElement:(NSString *)comments {
  if (comments.length == 0) {
    return;
  }

  [self appendString:
   [NSString stringWithFormat: @"<%@>%@</%@>\n",
    ScanCommentsElem,
    escapedXML(comments, CHARDATA_ESCAPE_CHARS),
    ScanCommentsElem]];
}


- (void) appendFilterSetElement:(FilterSet *)filterSet {
  if ([filterSet numFilters] == 0) {
    return;
  }

  [self appendString: [NSString stringWithFormat: @"<%@>\n", FilterSetElem]];

  NSEnumerator  *filterEnum = [[filterSet filters] objectEnumerator];
  NamedFilter  *namedFilter;
  while (namedFilter = [filterEnum nextObject]) {
    [self appendFilterElement: namedFilter];
  }

  [self appendString: [NSString stringWithFormat: @"</%@>\n", FilterSetElem]];
}


- (void) appendFilterElement:(NamedFilter *)namedFilter {
  Filter  *filter = [namedFilter filter];
  if ([filter numFilterTests] == 0) {
    return;
  }

  NSString  *nameVal = escapedXML([namedFilter name], ATTRIBUTE_ESCAPE_CHARS);
  NSString  *openElem = [NSString stringWithFormat: @"<%@ %@=\"%@\">\n",
                         FilterElem,
                         NameAttr, nameVal];
  [self appendString: openElem];

  NSEnumerator  *testEnum = [[filter filterTests] objectEnumerator];
  FilterTestRef  *filterTest;
  while (filterTest = [testEnum nextObject]) {
    [self appendFilterTestElement: filterTest];
  }

  [self appendString: [NSString stringWithFormat: @"</%@>\n", FilterElem]];
}


- (void) appendFilterTestElement:(FilterTestRef *)filterTest {
  NSString  *nameVal = escapedXML([filterTest name], ATTRIBUTE_ESCAPE_CHARS);
  [self appendString:
   [NSString stringWithFormat: @"<%@ %@=\"%@\" %@=\"%@\" />\n",
    FilterTestElem,
    NameAttr, nameVal,
    InvertedAttr,
    ([filterTest isInverted] ? TrueValue : FalseValue) ]];
}


- (void) appendFolderElement:(DirectoryItem *)dirItem {
  [progressTracker processingFolder: dirItem];

  NSString  *nameVal = escapedXML([dirItem systemPathComponent], ATTRIBUTE_ESCAPE_CHARS);

  FileItemOptions  flags = [dirItem fileItemFlags];
  NSString  *createdVal = [TreeWriter stringForTime: [dirItem creationTime]];
  NSString  *modifiedVal = [TreeWriter stringForTime: [dirItem modificationTime]];
  NSString  *accessedVal = [TreeWriter stringForTime: [dirItem accessTime]];
  [self appendString: [NSString stringWithFormat: @"<%@ %@=\"%@\"",
                       FolderElem,
                       NameAttr, nameVal]];
  if (flags != 0) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%d\"", FlagsAttr, flags]];
  }
  if (createdVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", CreatedAttr, createdVal]];
  }
  if (modifiedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", ModifiedAttr, modifiedVal]];
  }
  if (accessedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", AccessedAttr, accessedVal]];
  }
  [self appendString: @">\n"];

  [self dumpItemContents: dirItem.contents];

  [self appendString: [NSString stringWithFormat: @"</%@>\n", FolderElem]];

  [progressTracker processedFolder: dirItem];
  if ([progressTracker numFoldersProcessed] % AUTORELEASE_PERIOD == 0) {
    // Flush auto-release pool to prevent high memory usage while writing is in progress. The
    // temporary objects created while writing the tree can be four times larger in size than the
    // footprint of the actual tree in memory.
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
  }
}


- (void) appendFileElement:(FileItem *)fileItem {
  NSString  *nameVal = escapedXML([fileItem systemPathComponent], ATTRIBUTE_ESCAPE_CHARS);
  FileItemOptions  flags = [fileItem fileItemFlags];
  NSString  *createdVal = [TreeWriter stringForTime: [fileItem creationTime]];
  NSString  *modifiedVal = [TreeWriter stringForTime: [fileItem modificationTime]];
  NSString  *accessedVal = [TreeWriter stringForTime: [fileItem accessTime]];

  [self appendString: [NSString stringWithFormat: @"<%@ %@=\"%@\" %@=\"%qu\"",
                       FileElem,
                       NameAttr, nameVal,
                       SizeAttr, [fileItem itemSize]
                       ]];
  if (flags != 0) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%d\"", FlagsAttr, flags]];
  }
  if (createdVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", CreatedAttr, createdVal]];
  }
  if (modifiedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", ModifiedAttr, modifiedVal]];
  }
  if (accessedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", AccessedAttr, accessedVal]];
  }
  [self appendString: @"/>\n"];
}

@end // @implementation TreeWriter (PrivateMethods)
