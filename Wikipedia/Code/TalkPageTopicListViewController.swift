
import UIKit

protocol TalkPageTopicListDelegate: class {
    func tappedTopic(_ topic: TalkPageTopic, viewController: TalkPageTopicListViewController)
    func scrollViewDidScroll(_ scrollView: UIScrollView, viewController: TalkPageTopicListViewController)
    func updateNavigationBarTitle(title: String?, viewController: TalkPageTopicListViewController)
    func currentNavigationTitle(viewController: TalkPageTopicListViewController) -> String?
}

class TalkPageTopicListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageTopicListDelegate?
    
    private let dataStore: MWKDataStore
    private let talkPage: TalkPage
    private let fetchedResultsController: NSFetchedResultsController<TalkPageTopic>
    
    private let reuseIdentifier = "TalkPageTopicCell"
    
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageTopic>!
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    private var toolbar: UIToolbar?
    private var shareIcon: IconBarButtonItem?
    private var headerView: TalkPageHeaderView?
    
    required init(dataStore: MWKDataStore, talkPage: TalkPage) {
        self.dataStore = dataStore
        self.talkPage = talkPage
        
        let request: NSFetchRequest<TalkPageTopic> = TalkPageTopic.fetchRequest()
        request.predicate = NSPredicate(format: "talkPage == %@",  talkPage)
        request.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        setupCollectionViewUpdater()
        setupToolbar()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        delegate?.scrollViewDidScroll(scrollView, viewController: self)
        
        //todo: should refactor to lean on NavigationBar's extendedView
        if let headerView = headerView {
            navigationBar.shadowAlpha = (collectionView.contentOffset.y + collectionView.adjustedContentInset.top) > headerView.frame.height ? 1 : 0
            
            let convertedHeaderTitleFrame = headerView.convert(headerView.titleLabel.frame, to: view)
            
            let oldTitle = delegate?.currentNavigationTitle(viewController: self)
            let newTitle = (collectionView.contentOffset.y + collectionView.adjustedContentInset.top) > convertedHeaderTitleFrame.maxY ? talkPage.displayTitle : nil
            if oldTitle != newTitle {
                delegate?.updateNavigationBarTitle(title: newTitle, viewController: self)
            }
        } else {
            navigationBar.shadowAlpha = 0
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections,
            section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? TalkPageTopicCell else {
                return UICollectionViewCell()
        }
        
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        // The layout estimate can be re-used in this case because label is one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 54)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? TalkPageTopicCell else {
            return estimate
        }
        configure(cell: placeholderCell, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topic = fetchedResultsController.object(at: indexPath)
        delegate?.tappedTopic(topic, viewController: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TalkPageHeaderView.identifier, for: indexPath) as? TalkPageHeaderView else {
                return UICollectionReusableView()
        }
        
        configure(header: header)
        self.headerView = header
        return header
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let header = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TalkPageHeaderView.identifier) as? TalkPageHeaderView else {
            return estimate
        }
     
        configure(header: header)
        estimate.height = header.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        collectionView.backgroundColor = theme.colors.baseBackground
        toolbar?.barTintColor = theme.colors.chromeBackground
        shareIcon?.apply(theme: theme)
    }
}

//MARK: Private

private extension TalkPageTopicListViewController {
    
    func registerCells() {
        layoutManager.register(TalkPageTopicCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        layoutManager.register(TalkPageHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TalkPageHeaderView.identifier, addPlaceholder: true)
    }
    
    func setupCollectionViewUpdater() {
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        collectionViewUpdater?.performFetch()
    }
    
    func setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.barTintColor = theme.colors.chromeBackground
        
        let toolbarHeight = CGFloat(44)
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight, right: 0)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        let guide = view.safeAreaLayoutGuide
        let heightConstraint = toolbar.heightAnchor.constraint(equalToConstant: toolbarHeight)
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor)
        let trailingConstraint = view.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor)
        let bottomConstraint = guide.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        
        NSLayoutConstraint.activate([heightConstraint, leadingConstraint, trailingConstraint, bottomConstraint])
        
        let shareIcon = IconBarButtonItem(iconName: "share", target: self, action: #selector(shareTapped), for: .touchUpInside)
        shareIcon.apply(theme: theme)
        shareIcon.accessibilityLabel = CommonStrings.accessibilityShareTitle
        
        let spacer1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let spacer2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [spacer1, shareIcon, spacer2]

        self.toolbar = toolbar
        self.shareIcon = shareIcon
    }
    
    @objc func shareTapped() {
        print("share here")
    }
    
    func configure(cell: TalkPageTopicCell, at indexPath: IndexPath) {
        guard let title = fetchedResultsController.object(at: indexPath).title else {
            return
        }
        
        cell.configure(title: title)
        cell.layoutMargins = layout.itemLayoutMargins
        cell.apply(theme: theme)
    }
    
    func configure(header: TalkPageHeaderView) {
        
        guard let displayTitle = talkPage.displayTitle,
            let languageCode = talkPage.languageCode else {
                return
        }
        
        let headerText = WMFLocalizedString("talk-page-title-user-talk", value: "User Talk", comment: "This title label is displayed at the top of a talk page topic list. It represents the kind of talk page the user is viewing.").localizedUppercase
        let languageTextFormat = WMFLocalizedString("talk-page-info-active-conversations", value: "Active conversations on %1$@", comment: "This information label is displayed at the top of a talk page topic list. %1$@ is replaced by the language wiki they are using ('English Wikipedia').")
        
        //todo: fix for other languages
        var languageWikiText: String
        switch languageCode {
        case "en":
            languageWikiText = "English Wikipedia"
        case "test":
            languageWikiText = "Test Wikipedia"
        default:
            languageWikiText = ""
        }
        
        let infoText = NSString.localizedStringWithFormat(languageTextFormat as NSString, languageWikiText) as String
        
        let viewModel = TalkPageHeaderView.ViewModel(header: headerText, title: displayTitle, info: infoText)
        
        header.configure(viewModel: viewModel)
        header.layoutMargins = layout.itemLayoutMargins
        header.apply(theme: theme)
    }
}

//MARK: CollectionViewUpdaterDelegate

extension TalkPageTopicListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TalkPageTopicCell else {
                continue
            }
            
            configure(cell: cell, at: indexPath)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}
