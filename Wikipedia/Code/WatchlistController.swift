import Foundation
import WMF
import WKData

protocol WatchlistControllerDelegate: AnyObject {
    func didSuccessfullyWatch(_ controller: WatchlistController)
    func didSuccessfullyUnwatch(_ controller: WatchlistController)
}

/// This controller contains reusable logic for watching, updating expiry, and unwatching a page. It triggers the network service calls, as well as displays the appropriate toasts and action sheets based on the response.
class WatchlistController {
    
    private let service = WKWatchlistService()
    private weak var delegate: WatchlistControllerDelegate?
    private weak var lastPopoverPresentationController: UIPopoverPresentationController?
    
    init(delegate: WatchlistControllerDelegate) {
        self.delegate = delegate
    }
    
    func watch(pageTitle: String, siteURL: URL, expiry: WKWatchlistExpiryType = .never, viewController: UIViewController, authenticationManager: WMFAuthenticationManager, theme: Theme, sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?) {
        
        guard authenticationManager.isLoggedIn else {
            viewController.wmf_showLoginViewController(theme: theme)
            return
        }
        
        guard let wkProject = WikimediaProject(siteURL: siteURL)?.wkProject else {
            viewController.showGenericError()
            return
        }
        
        service.watch(title: pageTitle, project: wkProject, expiry: expiry) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                
                switch result {
                case .success:
                    self.displayWatchSuccessMessage(pageTitle: pageTitle, wkProject: wkProject, expiry: expiry, viewController: viewController, theme: theme, sender: sender, sourceView: sourceView, sourceRect: sourceRect, allowChangeExpiry: true)
                    self.delegate?.didSuccessfullyWatch(self)
                case .failure(let error):
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
                }
            }
        }
    }
    
    private func displayWatchSuccessMessage(pageTitle: String, wkProject: WKProject, expiry: WKWatchlistExpiryType, viewController: UIViewController, theme: Theme, sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?, allowChangeExpiry: Bool) {
        let statusTitle: String
        let image = UIImage(systemName: "star.fill")
        switch expiry {
        case .never:
            statusTitle = WMFLocalizedString("watchlist-added-toast-permanently", value: "Added to Watchlist permanently.", comment: "Title in toast after a user successfully adds an article to their watchlist, with no expiration.")
        case .oneWeek:
            statusTitle = WMFLocalizedString("watchlist-added-toast-one-week", value: "Added to Watchlist for 1 week.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in one week.")
        case .oneMonth:
            statusTitle = WMFLocalizedString("watchlist-added-toast-one-month", value: "Added to Watchlist for 1 month.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in one month.")
        case .threeMonths:
            statusTitle = WMFLocalizedString("watchlist-added-toast-three-months", value: "Added to Watchlist for 3 months.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in three months.")
        case .sixMonths:
            statusTitle = WMFLocalizedString("watchlist-added-toast-six-months", value: "Added to Watchlist for 6 months.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in 6 months.")
        }
        
        let promptTitle = allowChangeExpiry ? WMFLocalizedString("watchlist-added-toast-change-expiration", value: "Change expiration date?", comment: "Title in toast after a user successfully adds an article to their watchlist. Tapping will allow them to change their watchlist item expiration date.") : nil
        
        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(statusTitle, subtitle: nil, image: image, type: .custom, customTypeName: "subscription-success", dismissPreviousAlerts: true, buttonTitle: promptTitle, buttonCallBack: { [weak self] in
            guard allowChangeExpiry else {
                return
            }
            self?.presentExpiryUpdateActionSheet(pageTitle: pageTitle, wkProject: wkProject, expiry: expiry, viewController: viewController, theme: theme, sender: sender, sourceView: sourceView, sourceRect: sourceRect)
        })
    }
    
    private func presentExpiryUpdateActionSheet(pageTitle: String, wkProject: WKProject, expiry: WKWatchlistExpiryType, viewController: UIViewController, theme: Theme, sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?) {
        
        WMFAlertManager.sharedInstance.dismissAllAlerts()
        
        let title = WMFLocalizedString("watchlist-change-expiry-title", value: "Watchlist expiry", comment: "Title of modal that allows a user to change the expiry setting of a page they are watching.")
        let message = WMFLocalizedString("watchlist-change-expiry-subtitle", value: "Change Watchlist time period", comment: "Subtitle in modal that allows a user to change the expiry setting of a page they are watching.")
        
        let expiryOptionPermanent = WMFLocalizedString("watchlist-change-expiry-option-permanent", value: "Permanent", comment: "Title of button in expiry change modal that permanently watches a page.")
        
        let expiryOptionOneWeek = WMFLocalizedString("watchlist-change-expiry-option-one-week", value: "1 week", comment: "Title of button in expiry change modal that watches a page for one week.")
        
        let expiryOptionOneMonth = WMFLocalizedString("watchlist-change-expiry-option-one-month", value: "1 month", comment: "Title of button in expiry change modal that watches a page for one month.")
        
        let expiryOptionThreeMonths = WMFLocalizedString("watchlist-change-expiry-option-three-months", value: "3 months", comment: "Title of button in expiry change modal that watches a page for three months.")
        
        let expiryOptionSixMonths = WMFLocalizedString("watchlist-change-expiry-option-six-months", value: "6 months", comment: "Title of button in expiry change modal that watches a page for six months.")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let titles = [expiryOptionPermanent, expiryOptionOneWeek, expiryOptionOneMonth, expiryOptionThreeMonths, expiryOptionSixMonths]
        let expirys: [WKWatchlistExpiryType] = [.never, .oneWeek, .oneMonth, .threeMonths, .sixMonths]
        
        for (title, expiry) in zip(titles, expirys) {
            
            let action = UIAlertAction(title: title, style: .default) { [weak self] (action) in
                self?.service.watch(title: pageTitle, project: wkProject, expiry: expiry, completion: { result in
                    switch result {
                    case .success(()):
                        self?.displayWatchSuccessMessage(pageTitle: pageTitle, wkProject: wkProject, expiry: expiry, viewController: viewController, theme: theme, sender: sender, sourceView: sourceView, sourceRect: sourceRect, allowChangeExpiry: false)
                    case .failure(let error):
                        WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
                    }
                })
            }
            
            alertController.addAction(action)
            
        }
        
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            lastPopoverPresentationController = popoverController
            calculatePopoverPosition(sender: sender, sourceView: sourceView, sourceRect: sourceRect)
        }
        
        alertController.overrideUserInterfaceStyle = theme.isDark ? .dark : .light
        
        viewController.present(alertController, animated: true)
    }
    
    func unwatch(pageTitle: String, siteURL: URL, viewController: UIViewController, authenticationManager: WMFAuthenticationManager, theme: Theme) {
        
        guard authenticationManager.isLoggedIn else {
            viewController.wmf_showLoginViewController(theme: theme)
            return
        }
        
        guard let wkProject = WikimediaProject(siteURL: siteURL)?.wkProject else {
            viewController.showGenericError()
            return
        }
        
        service.unwatch(title: pageTitle, project: wkProject) { [weak self] result in
            
            DispatchQueue.main.async {
                
                guard let self else {
                    return
                }
                
                switch result {
                case .success:
                    let title = WMFLocalizedString("watchlist-removed", value: "Removed from your watchlist", comment: "Title in toast after a user successfully removes an article from their watchlist.")
                    let image = UIImage(systemName: "star")
                    WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: "subscription-success", dismissPreviousAlerts: true)
                    self.delegate?.didSuccessfullyUnwatch(self)
                case .failure(let error):
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
                }
            }
        }
    }
    
    func calculatePopoverPosition(sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?) {
        guard let lastPopoverPresentationController else {
            return
        }
        
        if let sourceView = sourceView,
           let sourceRect = sourceRect {
            lastPopoverPresentationController.sourceView = sourceView
            lastPopoverPresentationController.sourceRect = sourceRect
        } else {
            lastPopoverPresentationController.barButtonItem = sender
        }
    }
    
    static func calculateToolbarFifthButtonSourceRect(toolbarView: UIView, thirdButtonView: UIView, fourthButtonView: UIView) -> CGRect {
        
        let thirdButtonFrame = toolbarView.convert(thirdButtonView.frame, from: thirdButtonView.superview)
        let fourthButtonFrame = toolbarView.convert(fourthButtonView.frame, from: fourthButtonView.superview)
        
        let spacing = fourthButtonFrame.maxX - thirdButtonFrame.maxX
        
        let fifthFrame = CGRect(x: fourthButtonFrame.minX + spacing + 5, y: fourthButtonFrame.minY - 5, width: fourthButtonFrame.width, height: fourthButtonFrame.height)
        return fifthFrame
    }
}
