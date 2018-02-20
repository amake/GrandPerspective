#import "FilterTestRepository.h"

#import "FileItemTest.h"
#import "SelectiveItemTest.h"

#import "ItemSizeTestFinder.h"

#import "NotifyingDictionary.h"


// The key for storing user tests
NSString  *UserTestsKey = @"filterTests";

// The key for storing application-provided tests
NSString  *AppTestsKey = @"GPDefaultFilterTests";


@interface FilterTestRepository (PrivateMethods) 

- (void) addStoredTestsFromDictionary:(NSDictionary *)testDicts
                          toLiveTests:(NSMutableDictionary *)testsByName;

@end


@implementation FilterTestRepository

+ (id) defaultInstance {
  static FilterTestRepository  *defaultInstance = nil;

  if (defaultInstance == nil) {
    defaultInstance = [[FilterTestRepository alloc] init];
  }
  
  return defaultInstance;
}


- (instancetype) init {
  if (self = [super init]) {
    NSMutableDictionary  *initialTestDictionary = [NSMutableDictionary dictionaryWithCapacity: 16];
    
    // Load application-provided tests from the information properties file.
    NSBundle  *bundle = [NSBundle mainBundle];
      
    [self addStoredTestsFromDictionary: [bundle objectForInfoDictionaryKey: AppTestsKey]
                           toLiveTests: initialTestDictionary];
    applicationProvidedTests = [[NSDictionary alloc] initWithDictionary: initialTestDictionary];

    // Load additional user-created tests from preferences.
    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
    [self addStoredTestsFromDictionary: [userDefaults dictionaryForKey: UserTestsKey]
                           toLiveTests: initialTestDictionary];

    // Store tests in a NotifyingDictionary
    _testsByName =
      (NSDictionary *)[[NotifyingDictionary alloc] initWithCapacity: 16
                                                    initialContents: initialTestDictionary];
  }
  
  return self;
}

- (void) dealloc {
  [_testsByName release];
  [applicationProvidedTests release];

  [super dealloc];
}


- (NotifyingDictionary *)testsByNameAsNotifyingDictionary {
  return (NotifyingDictionary *)self.testsByName;
}


- (FileItemTest *)fileItemTestForName:(NSString *)name {
  return self.testsByName[name];
}

- (FileItemTest *)applicationProvidedTestForName:(NSString *)name {
  return applicationProvidedTests[name];
}


- (void) storeUserCreatedTests {
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSMutableDictionary  *testsDict = 
    [NSMutableDictionary dictionaryWithCapacity: self.testsByName.count];

  NSString  *name;
  NSEnumerator  *nameEnum = [self.testsByName keyEnumerator];

  while ((name = [nameEnum nextObject]) != nil) {
    FileItemTest  *fileItemTest = self.testsByName[name];

    if (fileItemTest != applicationProvidedTests[name]) {
      testsDict[name] = [fileItemTest dictionaryForObject];
    }
  }
    
  [userDefaults setObject: testsDict forKey: UserTestsKey];

  [userDefaults synchronize];
}

@end // @implementation FilterTestRepository


@implementation FilterTestRepository (PrivateMethods) 

- (void) addStoredTestsFromDictionary:(NSDictionary *)testDicts
                          toLiveTests:(NSMutableDictionary *)testsByNameVal {
  NSString  *name;
  NSEnumerator  *nameEnum = [testDicts keyEnumerator];

  while (name = [nameEnum nextObject]) {
    NSDictionary  *filterTestDict = testDicts[name];
    FileItemTest  *fileItemTest = [FileItemTest fileItemTestFromDictionary: filterTestDict];
    
    testsByNameVal[name] = fileItemTest;
  }
}


- (void) addStoredTestsFromArray:(NSArray *)testDicts
                     toLiveTests:(NSMutableDictionary *)testsByNameVal {
  NSDictionary  *fileItemTestDict;
  NSEnumerator  *fileItemTestDictEnum = [testDicts objectEnumerator];
  
  ItemSizeTestFinder  *sizeTestFinder = [[[ItemSizeTestFinder alloc] init] autorelease];

  while ((fileItemTestDict = [fileItemTestDictEnum nextObject]) != nil) {
    FileItemTest  *fileItemTest = [FileItemTest fileItemTestFromDictionary: fileItemTestDict];
    NSString  *name = fileItemTestDict[@"name"];
    
    // Update tests stored by older versions of GrandPerspective (pre 0.9.12).
    [sizeTestFinder reset];
    [fileItemTest acceptFileItemTestVisitor: sizeTestFinder];
    if ( [sizeTestFinder itemSizeTestFound] 
         && ! [fileItemTest isKindOfClass: [SelectiveItemTest class]] ) {
      // The test includes an ItemSizeTest, which should only be applied to files, yet it does not
      // use a SelectiveItemTest, so add one. This can happen because before Version 0.9.12 test
      // were only applied to files, so a SelectiveItemTest was not yet used, whereas it is needed
      // now that test can also be applied to folders. Note, there is no need to check for other
      // file-only tests, as these did not yet exist before Version 0.9.12.
      
      NSLog( @"Wrapping SelectiveItemTest around \"%@\" test.", name);
      
      FileItemTest  *subTest = fileItemTest;
      fileItemTest = [[[SelectiveItemTest alloc] initWithSubItemTest: subTest 
                                                           onlyFiles: YES] autorelease];
    }

    testsByNameVal[name] = fileItemTest;
  }
}

@end // @implementation FilterTestRepository (PrivateMethods) 
