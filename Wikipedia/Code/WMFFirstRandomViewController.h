#import <UIKit/UIKit.h>

@class MWKDataStore, WMFArticlePreviewDataStore;

//This VC is a placeholder to load the first random article

@interface WMFFirstRandomViewController : UIViewController

@property (nonatomic, strong, nonnull) NSURL *siteURL;
@property (nonatomic, strong, nonnull) MWKDataStore *dataStore;
@property (nonatomic, strong, nonnull) WMFArticlePreviewDataStore *previewStore;

- (nonnull instancetype)initWithSiteURL:(nonnull NSURL *)siteURL dataStore:(nonnull MWKDataStore *)dataStore previewStore:(nonnull WMFArticlePreviewDataStore*)previewStore NS_DESIGNATED_INITIALIZER;

@end
