#import <Cocoa/Cocoa.h>

/* A transformer that converts values (typically strings) to unique integer values. Once a value has
 * been assigned an integer tag, it always transforms to the same value. Furthermore, the reverse
 * transformation can then be used to get the original value again.
 *
 * This may all sound very abstract, but is in fact tremendously useful. It can be used for
 * localizing controls, in particular PopUpButtons. Each option is represented by a
 * locale-independent base name. These base names are used internally by the application, for
 * example to store preference values in a locale-independent, human-readable format.
 *
 * Localized pop-up buttons can be created as follows. It is populated by menu items, where each
 * title is a localized version of the base name, and where each tag derived from the basename.
 * These tags can be used to determine the base name corresponding to a selected item. (Note that
 * mapping localized names to base names directly does not work that well, because there can be
 * multiple base names that map to the same localized string).
 */
@interface UniqueTagsTransformer : NSValueTransformer {

  NSMutableDictionary  *valueToTag;
  NSMutableDictionary  *tagToValue;
  
  NSUInteger  nextTag;

}

+ (UniqueTagsTransformer *)defaultUniqueTagsTransformer;


/* Uses the transformer to add localized items to the pop-up. Each item has a tag associated with it
 * that allows easy mapping back to the original, locale-independent name.
 */
- (void) addLocalisedNames:(NSArray *)names
                   toPopUp:(NSPopUpButton *)popUp
                    select:(NSString *)selectName
                     table:(NSString *)tableName;

- (void) addLocalisedName:(NSString *)name 
                  toPopUp:(NSPopUpButton *)popUp
                   select:(BOOL)select
                    table:(NSString *)tableName;

/* Returns the locale-independent name for the given item. This works as long as the item was
 * created by this transformer using the -addLocalisedNamesToPopUp:names:select:table method.
 */
- (NSString *)nameForTag:(NSUInteger)tag;

/* Returns the tag for the locale-independent name.
 */
- (NSUInteger) tagForName:(NSString *)name;

@end
