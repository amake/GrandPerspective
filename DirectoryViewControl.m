#import "DirectoryViewControl.h"

#import "FileItem.h"
#import "DirectoryView.h"
#import "StartupControl.h"
#import "TreeNavigator.h"
#import "FileItemHashingOptions.h"

char BYTE_SIZE_ORDER[4] = { 'k', 'M', 'G', 'T'};

id makeSizeString(ITEM_SIZE size) {
  if (size < 1024) {
    // Definitely don't want a decimal point here
    return [NSString stringWithFormat:@"%qu B", size];
  }

  double  n = (double)size / 1024;
  int  m = 0;
  while (n > 1024 && m < 3) {
    m++;
    n /= 1024; 
  }

  NSMutableString*  s = 
    [[[NSMutableString alloc] initWithCapacity:12] autorelease];
  [s appendFormat:@"%.2f", n];
  int  delPos = [s rangeOfString:@"."].location!=3 ? 4 : 3;
  if (delPos < [s length]) {
    [s deleteCharactersInRange:NSMakeRange(delPos, [s length] - delPos)];
  }

  [s appendFormat:@" %cB", BYTE_SIZE_ORDER[m]];

  return s;
}

@interface DirectoryViewControl (PrivateMethods)

- (void) updateButtonState:(NSNotification*)notification;
- (void) visibleItemTreeChanged:(NSNotification*)notification;

@end  


@implementation DirectoryViewControl

// Special case: should not cover (override) super's designated initialiser in
// NSWindowController's case
- (id) initWithItemTree:(FileItem*)root {
  id  oldself = self;
  if (self = [super initWithWindowNibName:@"DirectoryViewWindow" owner:self]) {
    itemTreeRoot = [root retain];
    invisiblePathName = [[NSString alloc] init];
  }
  if (oldself != self) {
    NSLog(@"self changed.");
  }
  return self;
}

- (void) dealloc {
  NSLog(@"DirectoryViewControl-dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [itemTreeRoot release]; 
  
  [treeNavigator release];
  [invisiblePathName release];
  [hashingOptions release];
  
  [super dealloc];
}


- (FileItem*) itemTree {
  return itemTreeRoot;
}


- (void) windowDidLoad {
  hashingOptions = 
     [[FileItemHashingOptions defaultFileItemHashingOptions] retain];
  [colorMappingChoice addItemsWithObjectValues:
     [[hashingOptions allKeys] 
         sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
  [colorMappingChoice selectItemWithObjectValue:
     [hashingOptions keyForDefaultHashing]];
  [self colorMappingChanged:nil];
  
  treeNavigator = [[TreeNavigator alloc] initWithTree:itemTreeRoot];
  [mainView setTreeNavigator:treeNavigator];

  [super windowDidLoad];

  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(updateButtonState:)
      name:@"visibleItemPathChanged" object:treeNavigator];
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(updateButtonState:)
      name:@"visibleItemPathLockingChanged" object:treeNavigator];
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(visibleItemTreeChanged:)
      name:@"visibleItemTreeChanged" object:treeNavigator];
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(windowWillClose:)
      name:@"NSWindowWillCloseNotification" object:[self window]];

  [self updateButtonState:nil];

  [[self window] makeFirstResponder:mainView];
  [[self window] makeKeyAndOrderFront:self];
}

- (void) windowWillClose:(NSNotification*)notification {
  [self autorelease];
}

- (IBAction) upAction:(id)sender {
  [treeNavigator moveTreeViewUp];
}

- (IBAction) downAction:(id)sender {
  [treeNavigator moveTreeViewDown];
}

- (IBAction) colorMappingChanged:(id)sender {
  FileItemHashing*  fileItemHashing =
    [hashingOptions fileItemHashingForKey:
      [colorMappingChoice objectValueOfSelectedItem]];
      
  [mainView setFileItemHashing:fileItemHashing];
}

@end // @implementation DirectoryViewControl


@implementation DirectoryViewControl (PrivateMethods)

- (void) visibleItemTreeChanged:(NSNotification*)notification {
  
  [invisiblePathName release];
  invisiblePathName = [[NSMutableString alloc] initWithCapacity:128];

  NSEnumerator  *items;
  FileItem  *item;

  items = [[treeNavigator invisibleItemPath] objectEnumerator];
  [items nextObject]; // Skip first item
  while (item = [items nextObject]) {
    if ([invisiblePathName length] > 0) {
      // TODO: get directory separator from somewhere?
      [invisiblePathName appendString:@"/"];
    }

    [invisiblePathName appendString:[item name]];
  }

  [self updateButtonState:notification];
}


- (void) updateButtonState:(NSNotification*)notification {
  [upButton setEnabled:[treeNavigator canMoveTreeViewUp]];
  [downButton setEnabled:
     ([treeNavigator isVisibleItemPathLocked] &&
      [treeNavigator canMoveTreeViewDown])];

  [itemSizeLabel setStringValue:
     makeSizeString([[treeNavigator itemPathEndPoint] itemSize])];

  NSMutableString  *visiblePathName = [NSMutableString stringWithCapacity:128];  
  NSEnumerator  *items = [[treeNavigator visibleItemPath] objectEnumerator];
  FileItem  *item;

  while (item = [items nextObject]) {
    if ([visiblePathName length] > 0) {
      // TODO: get directory separator from somewhere?
      [visiblePathName appendString:@"/"];
    }

    [visiblePathName appendString:[item name]];    
  }

  NSMutableString  *name = 
    [[NSMutableString alloc] 
        initWithCapacity:[invisiblePathName length] +
                         [visiblePathName length] + 32];
  [name appendString:invisiblePathName];

  int  visibleStartPos = 0;
  if ([visiblePathName length] > 0) {
    if ([name length] > 0) {
      [name appendString:@"/"];
    }
    visibleStartPos = [name length];
    [name appendString:visiblePathName];
  }

  id  attributedName = [[NSMutableAttributedString alloc] initWithString:name];
   
  if ([visiblePathName length] > 0) {
    // Mark invisible part of path
    [attributedName addAttribute:NSForegroundColorAttributeName
      value:[NSColor darkGrayColor] 
      range:NSMakeRange(visibleStartPos, [name length] - visibleStartPos)];
  }
    
  [itemNameLabel setStringValue:attributedName];

  [name release];
  [attributedName release]; 
}

@end // @implementation DirectoryViewControl (PrivateMethods)
