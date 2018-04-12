import UIKit

@objc (WMFNavigationBarHiderDelegate)
public protocol NavigationBarHiderDelegate: NSObjectProtocol {
    func navigationBarHider(_ hider: NavigationBarHider, didSetNavigationBarPercentHidden: CGFloat, underBarViewPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool)
}


extension CGFloat {
    func wmf_adjustedForRange(_ lower: CGFloat, upper: CGFloat, step: CGFloat) -> CGFloat {
        if self < lower + step {
            return lower
        } else if self > upper - step {
            return upper
        } else if isNaN || isInfinite {
            return lower
        } else {
            return self
        }
    }

    var wmf_normalizedPercentage: CGFloat {
        return wmf_adjustedForRange(0, upper: 1, step: 0.01)
    }
}


@objc(WMFNavigationBarHider)
public class NavigationBarHider: NSObject {
    @objc public weak var navigationBar: NavigationBar?
    @objc public weak var delegate: NavigationBarHiderDelegate?
    
    fileprivate var isUserScrolling: Bool = false
    fileprivate var isScrollingToTop: Bool = false
    var initialScrollY: CGFloat = 0
    var initialNavigationBarPercentHidden: CGFloat = 0
    public var isNavigationBarHidingEnabled: Bool = true // setting this to false will only hide the extended view
    public var isHidingEnabled: Bool = true // setting this to false will disable hiding of nav bar, underbar view and extended view
    
    @objc public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, isHidingEnabled else {
            return
        }
        isUserScrolling = true
        initialScrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        initialNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
    }

    @objc public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, isHidingEnabled else {
            return
        }

        guard isUserScrolling || isScrollingToTop else {
            return
        }
        
        let animated = false

        let currentExtendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        var extendedViewPercentHidden = currentExtendedViewPercentHidden
        var navigationBarPercentHidden = currentNavigationBarPercentHidden

        let scrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        
        let extendedViewHeight = navigationBar.extendedView.frame.size.height
        if extendedViewHeight > 0 {
            extendedViewPercentHidden = (scrollY/extendedViewHeight).wmf_normalizedPercentage
        }
        
        let barHeight = navigationBar.bar.frame.size.height
        if !isNavigationBarHidingEnabled {
          navigationBarPercentHidden = 0
        } else if initialScrollY < extendedViewHeight + barHeight {
            navigationBarPercentHidden = ((scrollY - extendedViewHeight)/barHeight).wmf_normalizedPercentage
        } else if scrollY <= extendedViewHeight + barHeight {
            navigationBarPercentHidden = min(initialNavigationBarPercentHidden, ((scrollY - extendedViewHeight)/barHeight).wmf_normalizedPercentage)
        } else if initialNavigationBarPercentHidden == 0 && initialScrollY > extendedViewHeight + barHeight {
            navigationBarPercentHidden = ((scrollY - initialScrollY)/barHeight).wmf_normalizedPercentage
        }

        guard currentExtendedViewPercentHidden != extendedViewPercentHidden || currentNavigationBarPercentHidden !=  navigationBarPercentHidden else {
            return
        }
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    @objc public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let navigationBar = navigationBar, isHidingEnabled else {
            return
        }
        
        let extendedViewHeight = navigationBar.extendedView.frame.size.height
        let barHeight = navigationBar.bar.frame.size.height

        let top = 0 - scrollView.contentInset.top
        let targetOffsetY = targetContentOffset.pointee.y - top
        if targetOffsetY < extendedViewHeight + barHeight {
            if targetOffsetY < 0.5 * extendedViewHeight { // both visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top)
            } else if targetOffsetY < extendedViewHeight + 0.5 * barHeight  { // only nav bar visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight)
            } else if targetOffsetY < extendedViewHeight + barHeight {
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + barHeight)
            }
            return
        }
        
        if initialScrollY < extendedViewHeight + barHeight && targetOffsetY > extendedViewHeight + barHeight { // let it naturally hide
            return
        }

        isUserScrolling = false

        let animated = true

        let extendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        var navigationBarPercentHidden: CGFloat = currentNavigationBarPercentHidden
        if !isNavigationBarHidingEnabled {
            navigationBarPercentHidden = 0
        } else if velocity.y > 0 {
            navigationBarPercentHidden = 1
        } else if velocity.y < 0 {
            navigationBarPercentHidden = 0
        } else if navigationBarPercentHidden < 0.5 {
            navigationBarPercentHidden = 0
        } else {
            navigationBarPercentHidden = 1
        }
        
        guard navigationBarPercentHidden != currentNavigationBarPercentHidden else {
            return
        }

        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }

    @objc public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
    }

    @objc public func scrollViewWillScrollToTop(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, isHidingEnabled else {
            return
        }
        initialNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        initialScrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        isScrollingToTop = true
    }

    @objc public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        isScrollingToTop = false
    }

    @objc public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrollingToTop = false
    }
}
