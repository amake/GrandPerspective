#import <Cocoa/Cocoa.h>

#import "TreeWriter.h"

// XML elements
extern NSString  *ScanDumpElem;
extern NSString  *ScanInfoElem;
extern NSString  *ScanCommentsElem;
extern NSString  *FilterSetElem;
extern NSString  *FilterElem;
extern NSString  *FilterTestElem;
extern NSString  *FolderElem;
extern NSString  *FileElem;

// XML attributes of GrandPerspectiveScanDump
extern NSString  *AppVersionAttr;
extern NSString  *FormatVersionAttr;

// XML attributes of GrandPerspectiveScanInfo
extern NSString  *VolumePathAttr;
extern NSString  *VolumeSizeAttr;
extern NSString  *FreeSpaceAttr;
extern NSString  *ScanTimeAttr;
extern NSString  *FileSizeMeasureAttr;

// XML attributes of FilterTest
extern NSString  *InvertedAttr;

// XML attributes of Folder and File
extern NSString  *NameAttr;
extern NSString  *FlagsAttr;
extern NSString  *SizeAttr;
extern NSString  *CreatedAttr;
extern NSString  *ModifiedAttr;
extern NSString  *AccessedAttr;

// Formatting string used in XML
extern NSString  *DateTimeFormat;

@class AnnotatedTreeContext;
@class ProgressTracker;

@interface XmlTreeWriter : TreeWriter {

  FILE  *file;
  
  void  *dataBuffer;
  NSUInteger  dataBufferPos;
  
  NSAutoreleasePool  *autoreleasePool;
}

/* Writes the tree to file (in XML format). Returns YES if the operation completed successfully.
 * Returns NO if an error occurred, or if the operation has been aborted. In the latter case the
 * file will still be valid. It simply will not contain all files/folders in the tree.
 */
- (BOOL) writeTree:(AnnotatedTreeContext *)tree toFile:(NSString *)path;

@end
