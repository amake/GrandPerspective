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

/* Writes a tree to portable XML format. The entire tree can be restored from this data.
 */
@interface XmlTreeWriter : TreeWriter {
  NSAutoreleasePool  *autoreleasePool;
}
@end

@interface XmlTreeWriter (ProtectedMethods)

/* Writes the tree in XML format.
 */
- (void) writeTree:(AnnotatedTreeContext *)tree options:(id)options;

@end
