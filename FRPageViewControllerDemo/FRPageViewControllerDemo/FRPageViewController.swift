//
//  FRPageViewController.swift
//  FRPageViewControllerDemo
//
//  Created by Do Thi Hong Ha on 2/29/16.
//  Copyright © 2016 Yotel. All rights reserved.
//

import UIKit

enum FRPVCDirection {
    case Forward
    case Backward
}

enum FRPVCTabsWidthOption {
    case Equal
    case Proportional
}

internal enum FRPVCContentScrollState {
    case None
    case Scrolling(forward: Bool)
}

@objc protocol FRPageViewControllerDelegate: AnyObject {
    optional func fr_pageViewController(pageViewController: FRPageViewController, didMoveToPage pageIndex: Int)
    optional func fr_pageViewController(pageViewController: FRPageViewController, didMoveToViewController viewController: UIViewController)
}

class FRPageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: FRPageViewControllerDelegate?
    
    internal private(set) var viewControllers: [UIViewController]!
    private var _tabWidthOption = FRPVCTabsWidthOption.Equal
    var tabWidthOption : FRPVCTabsWidthOption {
        get {
            return _tabWidthOption
        }
        set {
            let oldValue = _tabWidthOption
            _tabWidthOption = newValue
            if (oldValue != newValue) {
                reloadTabs(true)
                reloadTabs(false)
            }
        }
    }
    
    private var _tabFont: UIFont?
    var tabFont : UIFont {
        get {
            return _tabFont ?? UIFont.boldSystemFontOfSize(15)
        }
        set {
            let oldValue = _tabFont
            _tabFont = newValue
            if (oldValue != newValue) {
                reloadTabs(true)
                reloadTabs(false)
            }
        }
    }
    
    private var _highlighterHeight : CGFloat = 2.0 {
        didSet {
            adjustHighlighterPosition(currentIndex)
            tabsCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: _highlighterHeight, right: 0)
        }
    }
    
    var highlighterHeight : CGFloat {
        get {
            return _highlighterHeight
        }
        set {
            _highlighterHeight = max(0, newValue)
        }
    }
    var highlighterColor: UIColor = UIColor.whiteColor() {
        didSet {
            if (highlighter != nil) {
                highlighter.backgroundColor = highlighterColor
            }
        }
    }
    private var _tabsHeight : CGFloat = 40.0 {
        didSet {
            if (tabsHeightConstraint != nil) {
                tabsHeightConstraint.constant = _tabsHeight + _highlighterHeight
            }
        }
    }
    private var tabsHeightConstraint: NSLayoutConstraint!
    var tabsHeight : CGFloat {
        get {
            return _tabsHeight
        }
        set {
            _tabsHeight = max(0, newValue)
        }
    }
    
    private var _tabTintColor = UIColor.whiteColor()
    var tabTintColor : UIColor {
        get {
            return _tabTintColor
        }
        set {
            let oldValue = _tabTintColor
            _tabTintColor = newValue
            if (oldValue != newValue) {
                reloadTabs(true)
            }
        }
    }
    
    private var _tabSubTintColor = UIColor.grayColor()
    var tabSubTintColor: UIColor  {
        get {
            return _tabSubTintColor
        }
        set {
            let oldValue = _tabSubTintColor
            _tabSubTintColor = newValue
            if (oldValue != newValue) {
                reloadTabs(false)
            }
        }
    }
    var tabContentDividerColor = UIColor.whiteColor() {
        didSet {
            dividerView.backgroundColor = tabContentDividerColor
        }
    }
    private var dividerHeightConstraint: NSLayoutConstraint!
    private var _tabContentDividerHeight : CGFloat = 2.0 {
        didSet {
            if (dividerHeightConstraint != nil) {
                dividerHeightConstraint.constant = tabContentDividerHeight
            }
        }
    }
    var tabContentDividerHeight : CGFloat {
        get {
            return _tabContentDividerHeight
        }
        set {
            _tabContentDividerHeight = max(newValue, 0)
        }
    }
    private var _selectedTabBackgroundColor = UIColor.clearColor()
    var selectedTabBackgroundColor : UIColor {
        get {
            return _selectedTabBackgroundColor
        }
        set {
            let oldValue = _selectedTabBackgroundColor
            _selectedTabBackgroundColor = newValue
            if (oldValue != newValue) {
                reloadTabs(true)
            }
        }
    
    }
    
    private var _unselectedTabBackgroundColor = UIColor.clearColor()
    var unselectedTabBackgroundColor : UIColor {
        get {
            return _unselectedTabBackgroundColor
        }
        set {
            let oldValue = _unselectedTabBackgroundColor
            _unselectedTabBackgroundColor = newValue
            if (oldValue != newValue) {
                reloadTabs(false)
            }
        }
        
    }
    
    private let tabsCollectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        cv.bounces = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsMultipleSelection = false
        return cv
    }()
    var tabsBackgroundColor = UIColor.clearColor() {
        didSet {
            tabsCollectionView.backgroundColor = tabsBackgroundColor
        }
    }
    
    private let contentScrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.tag = FRPageViewController.FRPVC_CONTENT_SCROLL_TAG
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.pagingEnabled = true
        scrollView.bounces = true
        scrollView.scrollsToTop = false
        return scrollView
    }()
    
    private let leftViewContainer = UIView()
    private let middleViewContainer = UIView()
    private let rightViewContainer = UIView()
    private var currentViewController: UIViewController? {
        willSet(newVC) {
            if let newVC = newVC where newVC != currentViewController {
                newVC.view.removeFromSuperview()
                newVC.removeFromParentViewController()
            }
            if let vc = currentViewController {
                vc.view.removeFromSuperview()
                vc.removeFromParentViewController()
            }
        }
        didSet {
            if let vc = currentViewController {
                if vc.parentViewController != self {
                    addChildViewController(vc)
                }
                
                if (vc.view.superview != middleViewContainer) {
                    middleViewContainer.addSubview(vc.view)
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                    let views = ["page": vc.view]
                    middleViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                    middleViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                }
                delegate?.fr_pageViewController?(self, didMoveToViewController: vc)
            }
        }
    }
    private var currentIndex : Int = 0 {
        //        willSet(newValue) {
        //            oldIndex = currentIndex
        //        }
        didSet {
            currentViewController = viewControllers[currentIndex]
            
            if currentIndex > 0 {
                leftViewController = viewControllers[currentIndex - 1]
            }
            else {
                leftViewController = nil
            }
            
            if currentIndex < numberOfPages - 1{
                rightViewController = viewControllers[currentIndex + 1]
            }
            else {
                rightViewController = nil
            }
            
            delegate?.fr_pageViewController?(self, didMoveToPage: currentIndex)
        }
    }
    private var numberOfPages = 0
    
    private static let FRPVC_TABS_SCROLL_TAG = 201
    private static let FRPVC_CONTENT_SCROLL_TAG = 202
    
    private var highlighter : UIView!
    
    private var dividerView = UIView()
    
    private var leftViewController: UIViewController? {
        willSet(newVC) {
            if let newVC = newVC where newVC != leftViewController {
                newVC.view.removeFromSuperview()
                newVC.removeFromParentViewController()
            }
            
            if let vc = leftViewController where vc != currentViewController && vc != rightViewController {
                vc.view.removeFromSuperview()
                vc.removeFromParentViewController()
            }
        }
        didSet {
            if let vc = leftViewController {
                if (vc.parentViewController != self) {
                    addChildViewController(vc)
                }
                if vc.view.superview != leftViewContainer {
                    leftViewContainer.addSubview(vc.view)
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                    let views = ["page": vc.view]
                    leftViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                    leftViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                }
            }
        }
    }
    private var rightViewController: UIViewController? {
        willSet(newVC) {
            if let newVC = newVC where newVC != rightViewController {
                newVC.view.removeFromSuperview()
                newVC.removeFromParentViewController()
            }
            
            if let vc = rightViewController where vc != currentViewController && vc != leftViewController {
                vc.view.removeFromSuperview()
                vc.removeFromParentViewController()
            }
        }
        didSet {
            if let vc = rightViewController {
                if (vc.parentViewController != self) {
                    addChildViewController(vc)
                }
                if vc.view.superview != rightViewContainer {
                    rightViewContainer.addSubview(vc.view)
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                    let views = ["page": vc.view]
                    rightViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                    rightViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                }
            }
        }
    }
    private init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    private convenience init(viewControllers: [UIViewController], defaultIndex: Int) {
        assert(viewControllers.count != 0, "Empty view controllers array")
        self.init()
        self.viewControllers = viewControllers
        numberOfPages = viewControllers.count
        currentIndex = defaultIndex
        contentScrollView.delegate = self
    }
    
    private var tabTitles: [String]?
    
    convenience init(viewControllers: [UIViewController], tabTitles: [String], defaultIndex: Int = 0) {
        assert(viewControllers.count == tabTitles.count, "Number of view controllers is not equal to that of titles")
        self.init(viewControllers: viewControllers, defaultIndex: defaultIndex)
        self.tabTitles = tabTitles
    }
    
    
    private var selectedTabViews: [UIView]?
    private var unselectedTabViews: [UIView]?
    
    convenience init(viewControllers: [UIViewController], selectedTabViews: [UIView], unselectedTabViews:[UIView], defaultIndex: Int = 0) {
        assert(viewControllers.count == selectedTabViews.count && viewControllers.count == unselectedTabViews.count, "Number of view controllers is not equal to that of tab views")
        self.init(viewControllers: viewControllers, defaultIndex: defaultIndex)
        self.selectedTabViews = selectedTabViews
        self.unselectedTabViews = unselectedTabViews
    }
    
    private var selectedTabImages: [UIImage]?
    private var unselectedTabImages: [UIImage]?
    var minTabWidth: CGFloat = 40 {
        didSet {
            calculateTabWidths()
        }
    }

    
    convenience init(viewControllers: [UIViewController], selectedTabImages: [UIImage], unselectedTabImages: [UIImage], minTabWidth: CGFloat, defaultIndex: Int = 0) {
        assert(viewControllers.count == selectedTabImages.count && viewControllers.count == unselectedTabImages.count, "Number of view controllers is not equal to that of tab images")
        self.init(viewControllers: viewControllers, defaultIndex: defaultIndex)
        self.selectedTabImages = selectedTabImages
        self.unselectedTabImages = unselectedTabImages
        self.minTabWidth = minTabWidth
    }
    
    convenience init(viewControllers: [UIViewController], renderedTabImages: [UIImage], minTabWidth: CGFloat, defaultIndex: Int = 0) {
        assert(viewControllers.count == renderedTabImages.count, "Number of view controllers is not equal to that of tab images")
        self.init(viewControllers: viewControllers, defaultIndex: defaultIndex)
        selectedTabImages = renderedTabImages
        self.minTabWidth = minTabWidth
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var tabWidths: [CGFloat] = [CGFloat]()
    private var requiredTabWidths = [CGFloat]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
         setupChildrenViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutContentViews(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupChildrenViews() {
        view.addSubview(tabsCollectionView)
        tabsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dividerView)
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        var views : [String: UIView] = ["tabsScroll" : tabsCollectionView,
            "contentScroll": contentScrollView,
            "divider": dividerView]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[tabsScroll]-0-[divider]-0-[contentScroll]-0-|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[tabsScroll]-0-|", options: [], metrics: nil, views: views))
        tabsHeightConstraint = NSLayoutConstraint(item: tabsCollectionView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: _tabsHeight + _highlighterHeight)
        dividerHeightConstraint = NSLayoutConstraint(item: dividerView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: _tabContentDividerHeight)
        view.addConstraints([tabsHeightConstraint, dividerHeightConstraint])
        
        tabsCollectionView.registerClass(FRPVCTabIconCell.self, forCellWithReuseIdentifier: "IconCell")
        tabsCollectionView.registerClass(FRVCTabRenderedIconCell.self, forCellWithReuseIdentifier: "RenderedIconCell")
        tabsCollectionView.registerClass(FRPVCTabSubviewCell.self, forCellWithReuseIdentifier: "SubviewCell")
        tabsCollectionView.registerClass(FRPVCTabTitleCell.self, forCellWithReuseIdentifier: "TitleCell")
        tabsCollectionView.delegate = self
        tabsCollectionView.dataSource = self
        tabsCollectionView.backgroundColor = tabsBackgroundColor
        
        tabsCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: _highlighterHeight, right: 0)
        calculateTabWidths()
        
        // *** Content
        let contentContainer = UIView()
        contentContainer.backgroundColor = UIColor.clearColor()
        contentScrollView.addSubview(contentContainer)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        views["container"] = contentContainer
        contentScrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[container]-0-|", options: [], metrics: nil, views: views))
        contentScrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[container(contentScroll)]-0-|", options: [], metrics: nil, views: views))
        view.addConstraint(NSLayoutConstraint(item: contentContainer, attribute: .Width, relatedBy: .Equal, toItem: contentScrollView, attribute: .Width, multiplier: 3.0, constant: 0.0))
        
        for view in [leftViewContainer, middleViewContainer, rightViewContainer] {
            view.backgroundColor = UIColor.clearColor()
            contentContainer.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        views["view1"] = leftViewContainer
        views["view2"] = middleViewContainer
        views["view3"] = rightViewContainer
        contentContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view1(view2)]-0-[view2(view3)]-0-[view3]-0-|", options: [.AlignAllTop, .AlignAllBottom], metrics: nil, views: views))
        contentContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view1]-0-|", options: [], metrics: nil, views: views))
        
        currentViewController = viewControllers[currentIndex]
        if let vc = currentViewController {
            addChildViewController(vc)
            middleViewContainer.addSubview(vc.view)
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            let views = ["page": vc.view]
            middleViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
            middleViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        }
        
        if currentIndex > 0 {
            leftViewController = viewControllers[currentIndex - 1]
            if let vc = leftViewController {
                addChildViewController(vc)
                leftViewContainer.addSubview(vc.view)
                vc.view.translatesAutoresizingMaskIntoConstraints = false
                let views = ["page": vc.view]
                leftViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                leftViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
            }
        }
        
        if currentIndex < numberOfPages - 1 {
            rightViewController = viewControllers[currentIndex + 1]
            if let vc = rightViewController {
                addChildViewController(vc)
                rightViewContainer.addSubview(vc.view)
                vc.view.translatesAutoresizingMaskIntoConstraints = false
                let views = ["page": vc.view]
                rightViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
                rightViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
            }
        }
        view.updateConstraintsIfNeeded()
        view.layoutIfNeeded()
        
        view.addObserver(self, forKeyPath: "bounds", options: [.New], context: nil)
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        if let _ = tabsCollectionView.superview {
            return
        }
       
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func layoutContentViews(animated: Bool) {
        let viewWidth = contentScrollView.bounds.width
        contentScrollView.setContentOffset(CGPoint(x: viewWidth, y: 0), animated: animated)
        var leftInset:CGFloat = 0
        var rightInset:CGFloat = 0
        
        if (leftViewController == nil) {
            leftInset = -viewWidth
        }
        
        if (rightViewController == nil) {
            rightInset = -viewWidth
        }
        
        contentScrollView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, rightInset)
    }

    func reloadTabs(selected: Bool) {
        guard tabsCollectionView.dataSource != nil && currentIndex < numberOfPages && currentIndex >= 0 else {
            return
        }
        if (selected) {
            tabsCollectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: currentIndex, inSection: 0)])
        }
        else {
            let idxPaths = (0...numberOfPages).filter({$0 != currentIndex}).map({NSIndexPath(forRow: $0, inSection: 0)})
            tabsCollectionView.reloadItemsAtIndexPaths(idxPaths)
        }
    }
    
    private func calculateTabWidths() {
        calculateRequiredTabsWidth()
        calculateFinalTabWidths()
    }
    
    private func calculateFinalTabWidths() {
        let maxWidth = requiredTabWidths[numberOfPages]
        var totalWidth = requiredTabWidths[numberOfPages + 1]
        if tabWidthOption == .Equal {
            totalWidth = maxWidth * CGFloat(numberOfPages)
        }

        let ratio = max(1, view.frame.size.width / totalWidth)
        if (tabWidthOption == .Equal) {
            tabWidths = [CGFloat](count: numberOfPages, repeatedValue: ceil(maxWidth * ratio))
        }
        else {
            tabWidths = requiredTabWidths[0..<numberOfPages].map({ceil($0 * ratio)})
        }
        tabsCollectionView.reloadData()
        tabsCollectionView.selectItemAtIndexPath(NSIndexPath(forRow: currentIndex, inSection: 0), animated: true, scrollPosition: .CenteredHorizontally)
        adjustHighlighterPosition(currentIndex)
    }
    
    private func calculateRequiredTabsWidth() {
        requiredTabWidths.removeAll()
        var maxWidth: CGFloat = 0
        var totalWidth: CGFloat = 0
        let cellFrame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: _tabsHeight)
        if let titles = tabTitles {
            let sampleCell = FRPVCTabTitleCell(frame: cellFrame)
            _tabFont = _tabFont ?? UIFont.boldSystemFontOfSize(15)
            sampleCell.font = _tabFont!
            sampleCell.minWidth = minTabWidth
            for t in titles {
                sampleCell.title = t
                let width = sampleCell.requiredCellWidth()
                maxWidth = max(width, maxWidth)
                requiredTabWidths.append(width)
                totalWidth += width
            }
        }
        else if let _ = selectedTabImages {
            let sampleCell = FRPVCTabIconCell(frame: cellFrame)
            sampleCell.minWidth = minTabWidth
            let width = sampleCell.requiredCellWidth()
            maxWidth = width
            requiredTabWidths.appendContentsOf([CGFloat](count: numberOfPages, repeatedValue: width))
            totalWidth = width * CGFloat(numberOfPages)
        }
        else if let selectedTabViews = selectedTabViews,
            unselectedTabViews = unselectedTabViews {
                let sampleCell = FRPVCTabSubviewCell(frame: cellFrame)
                sampleCell.minWidth = minTabWidth
                for i in 0 ... numberOfPages - 1 {
                    sampleCell.selectedSubview = selectedTabViews[i]
                    sampleCell.unselectedSubview = unselectedTabViews[i]
                    let width = sampleCell.requiredCellWidth()
                    maxWidth = max(width, maxWidth)
                    requiredTabWidths.append(width)
                    totalWidth += width
                }
        }
        requiredTabWidths.append(maxWidth)
        requiredTabWidths.append(totalWidth)
    }
    
    func adjustHighlighterPosition(newIndex: Int) {
        guard numberOfPages > 0 && newIndex < numberOfPages && tabWidths.count == numberOfPages else {
            return
        }
        var orgX : CGFloat = 0
        var i = 0
        while i < newIndex {
            orgX += tabWidths[i]
            i++
        }
        let highlighterFrame = CGRect(x: orgX, y: _tabsHeight, width: tabWidths[i], height: _highlighterHeight)
        if (highlighter == nil) { // First time adjust
            highlighter = UIView(frame: highlighterFrame)
            highlighter.backgroundColor = highlighterColor
            tabsCollectionView.addSubview(highlighter)
        }
        else {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.highlighter.frame = highlighterFrame
                }, completion: { (fished) -> Void in
                    var newRect = highlighterFrame
                    if (newIndex > 0) {
                        newRect.origin.x -= 30
                        newRect.size.width += 30
                    }
                    if (newIndex < self.numberOfPages - 1) {
                        newRect.size.width += 30
                    }
                    newRect.origin.y = self.tabsHeight / 2
                    self.tabsCollectionView.scrollRectToVisible(newRect, animated: true)
            })
        }
    }
    
    //MARK: -
//    private var isTabSelectedProgrammatically = false
    func moveToPageAtIndex(newIndex: Int) {
        assert(newIndex >= 0 && newIndex < numberOfPages, "Invalid page index")
        
        if (newIndex == currentIndex) {
            return
        }
        
        let forward = currentIndex < newIndex
        
        if (forward) {
            rightViewController = viewControllers[newIndex]
        }
        else {
            leftViewController = viewControllers[newIndex]
        }
        
        if let selectedIP = tabsCollectionView.indexPathsForSelectedItems()?.first
            where selectedIP.row == newIndex { //ingnore it
                
        }
        else {
//            isTabSelectedProgrammatically = true
            tabsCollectionView.selectItemAtIndexPath(NSIndexPath(forRow: newIndex, inSection: 0), animated: true, scrollPosition: .CenteredHorizontally)
        }
        isTabTapped = true
        scrollAnimated(true, forward: forward) {
            self.currentIndex = newIndex
            self.layoutContentViews(false)
            self.isTabTapped = false
        }
        adjustHighlighterPosition(newIndex)
    }
    
    // MARK: Transit views
    
    func scrollAnimated(animated: Bool, forward: Bool, completion: ()->()) {
        if let _ = (forward ? rightViewController : leftViewController) {
            let xOffset = forward ? contentScrollView.bounds.width * 2 : 0
            if animated && scrollingState == FRPVCContentScrollState.None {
                scrollingState = .Scrolling(forward: forward)
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.contentScrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: false)
                    }, completion: { (finished) -> Void in
                        if (finished) {
                            self.scrollingState = .None
                            completion()
                        }
                })
            }
            else {
                contentScrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: false)
                completion()
            }
        }
    }

    //MARK: Collection view data source
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (numberOfPages != tabWidths.count) {
            return 0
        }
        return numberOfPages
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(tabWidths[indexPath.row], _tabsHeight)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var output: FRPVCTabCell!
        if let titles = tabTitles {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TitleCell", forIndexPath: indexPath) as! FRPVCTabTitleCell
            cell.title = titles[indexPath.row]
            cell.font = tabFont
            output = cell
        }
        else if let selectedTabImages = selectedTabImages {
            if let unselectedTabImages = unselectedTabImages {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("IconCell", forIndexPath: indexPath) as! FRPVCTabIconCell
                cell.highlightImage = selectedTabImages[indexPath.row]
                cell.normalImage = unselectedTabImages[indexPath.row]
                output = cell
            }
            else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RenderedIconCell", forIndexPath: indexPath) as! FRVCTabRenderedIconCell
                cell.image = selectedTabImages[indexPath.row]
                output = cell
            }
        }
        else if let selectedTabViews = selectedTabViews,
            unselectedTabViews = unselectedTabViews {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SubviewCell", forIndexPath: indexPath) as! FRPVCTabSubviewCell
                cell.selectedSubview = selectedTabViews[indexPath.row]
                cell.unselectedSubview = unselectedTabViews[indexPath.row]
                output = cell
        }
        output.highlightTintColor = _tabTintColor
        output.normalTintColor = _tabSubTintColor
        output.minWidth = minTabWidth
        output.selected = indexPath.row == currentIndex

        return output
    }
    
    // MARK: - Collection view delegate
    private var isTabTapped = false
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        if (indexPath.row == currentIndex || isTabSelectedProgrammatically) {
//            isTabSelectedProgrammatically = false
//            return
//        }
        if (indexPath.row == currentIndex) {
            return
        }
//        tabsCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
        isTabTapped = true
        moveToPageAtIndex(indexPath.row)
    }
    
    // MARK: - Scroll view delegate
    
    private var scrollingState = FRPVCContentScrollState.None
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if isTabTapped {
            return
        }
        if (scrollView.tag == FRPageViewController.FRPVC_CONTENT_SCROLL_TAG) {
            let viewWidth = scrollView.bounds.size.width
            let progress = (scrollView.contentOffset.x - viewWidth) / viewWidth
            if progress != 0 {
                let forward = progress > 0
                if let dest = (forward ? rightViewController : leftViewController) {
                    scrollingState = FRPVCContentScrollState.Scrolling(forward: forward)
                    let ap = abs(progress)
                    if (ap < 1) {
                        let seeingIndex = forward ? currentIndex + 1 : currentIndex - 1
                        let cell = tabsCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: seeingIndex, inSection: 0)) as! FRPVCTabCell
                        if (seeingIndex < numberOfPages && seeingIndex >= 0) {
                            if let (tred, tgreen, tblue, talpha) = _tabTintColor.colorComponents(),
                                let (sred, sgreen, sblue, salpha) = _tabSubTintColor.colorComponents() {
                                    let newAlpha = salpha + (talpha - salpha) * ap
                                    let newRed = sred + (tred - sred) * ap
                                    let newBlue = sblue + (tblue - sblue) * ap
                                    let newGreen = sgreen + (tgreen - sgreen) * ap
                                    let color = UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
                                    cell.normalTintColor = color
                            }
                            
                            if let (tred, tgreen, tblue, talpha) = selectedTabBackgroundColor.colorComponents(),
                                let (sred, sgreen, sblue, salpha) = unselectedTabBackgroundColor.colorComponents() {
                                    let newAlpha = salpha + (talpha - salpha) * ap
                                    let newRed = sred + (tred - sred) * ap
                                    let newBlue = sblue + (tblue - sblue) * ap
                                    let newGreen = sgreen + (tgreen - sgreen) * ap
                                    cell.backgroundColor = UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
                            }
                        }
                        
                    }
                    else {
                        didScrollTo(dest, animated: false)
                    }
                }
            }
        }
    }
    
    
    private func didScrollTo(destinatedViewController: UIViewController?, animated: Bool) {
        isTabTapped = false
        scrollingState = .None
        
        if destinatedViewController === currentViewController {
            return
        }
        
        if (destinatedViewController === rightViewController) {
            currentIndex++
        } else if (destinatedViewController === leftViewController) {
            currentIndex--
        }
        let cell = tabsCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentIndex, inSection: 0)) as! FRPVCTabCell
        cell.normalTintColor = _tabSubTintColor
        layoutContentViews(animated)
//        isTabSelectedProgrammatically = true
        tabsCollectionView.selectItemAtIndexPath(NSIndexPath(forRow: currentIndex, inSection: 0), animated: true, scrollPosition: .CenteredHorizontally)
        adjustHighlighterPosition(currentIndex)
    }
    
    // MARK: -
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let kp = keyPath where kp == "bounds" {
                calculateFinalTabWidths()
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    deinit {
        view.removeObserver(self, forKeyPath: "bounds")
    }
}

func == (left:FRPVCContentScrollState, right:FRPVCContentScrollState) -> Bool {
    switch (left, right) {
    case (FRPVCContentScrollState.None, FRPVCContentScrollState.None): return true
    case (FRPVCContentScrollState.Scrolling(let lforward), FRPVCContentScrollState.Scrolling(let rforward)):
        return lforward == rforward
    default:
        return false
    }
}

func != (left:FRPVCContentScrollState, right:FRPVCContentScrollState) -> Bool {
    return !(left == right)
}