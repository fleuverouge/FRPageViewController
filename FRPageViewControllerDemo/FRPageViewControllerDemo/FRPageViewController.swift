//
//  FRPageViewController.swift
//  FRPageViewControllerDemo
//
//  Created by Do Thi Hong Ha on 1/13/16.
//  Copyright © 2016 Yotel. All rights reserved.
//

import UIKit

enum FRDirection {
    case Forward
    case Backward
}

enum FRSegementWidthOption {
    case EqualWidth(minWidth: CGFloat)
    case ProportionalWidth
}

internal enum FRPVCContentScrollState {
    case None
    case Scrolling(Bool)
}

@objc protocol FRPageViewControllerDelegate: AnyObject {
    optional func didMoveToPage(index: Int, pageViewController: FRPageViewController)
    optional func didMoveToViewController(viewController: UIViewController?, pageViewController: FRPageViewController)
}

protocol FRPageViewControllerDataSource: AnyObject {
    func viewControllerAtIndex(index: Int, pageViewController: FRPageViewController) -> UIViewController?
}

class FRPageViewController: UIViewController, UIScrollViewDelegate {
    weak var datasource: FRPageViewControllerDataSource?
    weak var delegate: FRPageViewControllerDelegate?
    
    var tabWidthOption = FRSegementWidthOption.EqualWidth(minWidth: 0)
    var tabFont = UIFont.boldSystemFontOfSize(15)
    var highlighterHeight : CGFloat = 2.0
    var tabsHeight : CGFloat = 42.0
    var tintColor = UIColor.redColor() {
        didSet {
            highlighter?.backgroundColor = tintColor
        }
    }
    var subTintColor = UIColor.grayColor()
    var tabContentDividerColor = UIColor.redColor() {
        didSet {
            dividerView?.backgroundColor = tabContentDividerColor
        }
    }
    var tabContentDividerHeight : CGFloat = 2.0
    var selectedTabBackgroundColor = UIColor.clearColor()
    var unselectedTabBackgroundColor = UIColor.clearColor()
    
    private let tabsScrollView = UIScrollView()
    private let contentScrollView = UIScrollView()
    private let leftViewContainer = UIView()
    private let middleViewContainer = UIView()
    private let rightViewContainer = UIView()
    private var tabButtons = [UIButton]()
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
            }
            delegate?.didMoveToViewController?(currentViewController, pageViewController: self)
        }
    }
    private var currentIndex : Int {
        willSet(newValue) {
            oldIndex = currentIndex
        }
        didSet {
            currentViewController = datasource?.viewControllerAtIndex(currentIndex, pageViewController: self)
            
            if currentIndex > 0 {
                leftViewController = datasource?.viewControllerAtIndex(currentIndex - 1, pageViewController: self)
            }
            else {
                leftViewController = nil
            }
            
            if currentIndex < numberOfPages - 1{
                rightViewController = datasource?.viewControllerAtIndex(currentIndex + 1, pageViewController: self)
            }
            else {
                rightViewController = nil
            }
            
            delegate?.didMoveToPage?(currentIndex, pageViewController: self)
        }
    }
    private var oldIndex = 0
    private var numberOfPages = 0
    
    private static let FRPVC_BUTTON_TAG = 101
    private static let FRPVC_TABS_SCROLL_TAG = 201
    private static let FRPVC_CONTENT_SCROLL_TAG = 202
    private static let FRPVC_SELECTED_TAB_VIEW_TAG = 301
    private static let FRPVC_UNSELECTED_TAB_VIEW_TAG = 302
    
    private var highlighterContraints: [NSLayoutConstraint]?
    private var highlighter: UIView?
    
    private var dividerView: UIView?
    
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
    
    // MARK: - Initialization
    
    private init(currentIndex: Int = 0) {

        self.currentIndex = currentIndex
        super.init(nibName: nil, bundle: nil)
        
        tabsScrollView.delegate = self
        tabsScrollView.tag = FRPageViewController.FRPVC_TABS_SCROLL_TAG
        tabsScrollView.backgroundColor = UIColor.clearColor()
        tabsScrollView.showsVerticalScrollIndicator = false
        tabsScrollView.showsHorizontalScrollIndicator = false
        tabsScrollView.pagingEnabled = true
        tabsScrollView.bounces = true
        tabsScrollView.scrollsToTop = false
        tabsScrollView.canCancelContentTouches = false
        
        contentScrollView.delegate = self
        contentScrollView.tag = FRPageViewController.FRPVC_CONTENT_SCROLL_TAG
        contentScrollView.backgroundColor = UIColor.clearColor()
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.pagingEnabled = true
        contentScrollView.bounces = true
        contentScrollView.scrollsToTop = false
    }
    
    private var selectedTabBackgroundImages : [UIImage]?
    private var unselectedTabBackgroundImages: [UIImage]?
    
    convenience init(titles: [String], selectedTabBackgroundImages: [UIImage]? = nil, unselectedTabBackgroundImages: [UIImage]? = nil, displayedIndex: Int = 0) {

        self.init(currentIndex: displayedIndex)
        
        var selectedTabViews = [UIImageView]()
        var unselectedTabViews = [UIImageView]()
        
        for i in 0...titles.count - 1 {
            let button = UIButton(type: .Custom)
            button.setTitle(titles[i], forState: .Normal)
            button.titleLabel!.textAlignment = .Center
            tabButtons.append(button)
            
            if let imgs = selectedTabBackgroundImages {
                let image = imgs[i % imgs.count]
                let imageView = UIImageView(image: image)
                imageView.contentMode = .ScaleAspectFill
                selectedTabViews.append(imageView)
            }
            
            if let imgs = unselectedTabBackgroundImages {
                let image = imgs[i % imgs.count]
                let imageView = UIImageView(image: image)
                imageView.contentMode = .ScaleAspectFill
                unselectedTabViews.append(imageView)
            }
        }
        
        addTabViews(selectedTabViews, selected: true)
        addTabViews(unselectedTabViews, selected: false)
        
        didIntializeController()
    }
    
    convenience init(images:[UIImage], unselectedImages: [UIImage]? = nil, minimumWidth: CGFloat, displayedIndex: Int = 0) {
        self.init(currentIndex: displayedIndex)
        
        tabWidthOption = .EqualWidth(minWidth: minimumWidth)
        
        if let imgs = unselectedImages {
            var selectedTabViews = [UIImageView]()
            for image in images {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .ScaleAspectFit
                selectedTabViews.append(imageView)
            }
            addTabViews(selectedTabViews, selected: true, minimumWidth: minimumWidth)
            
            var unselectedTabViews = [UIImageView]()
            for image in imgs {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .ScaleAspectFit
                unselectedTabViews.append(imageView)
            }
            addTabViews(unselectedTabViews, selected: false, minimumWidth: minimumWidth)
        }
        
        else {
            for image in images {
                let button = UIButton(type: .Custom)
                button.setImage(image, forState: .Normal)
                button.imageView?.contentMode = .ScaleAspectFit
                tabButtons.append(button)
            }
        }
        
        didIntializeController()
    }
    
    convenience init(selectedTabViews: [UIView], unselectedTabViews: [UIView], minimumWidth: CGFloat, displayedIndex: Int = 0) {
        assert(selectedTabViews.count == unselectedTabViews.count, "Unbalanced selected views and unselected views")
        
        self.init(currentIndex: displayedIndex)
        
        tabWidthOption = .EqualWidth(minWidth: minimumWidth)
        addTabViews(selectedTabViews, selected: true, minimumWidth: minimumWidth)
        addTabViews(unselectedTabViews, selected: false, minimumWidth: minimumWidth)
        
        didIntializeController()
    }
    
    func didIntializeController() {
        numberOfPages = tabButtons.count
        assert(numberOfPages != 0, "Invalid number of pages")
        assert(currentIndex >= 0 && currentIndex < numberOfPages, "Starting index out of range")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.addSubview(tabsScrollView)
        tabsScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        highlighterHeight = max(0, highlighterHeight)
        tabContentDividerHeight = max(0, tabContentDividerHeight)
        var views : [String: UIView] = ["tabsScroll" : tabsScrollView,
            "contentScroll": contentScrollView]
        var metrics = ["tabsHeight": tabsHeight + highlighterHeight + tabContentDividerHeight]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[tabsScroll]-0-|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[tabsScroll(tabsHeight)]-0-[contentScroll]-0-|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: metrics, views: views))
        
        // *** Tabs
        let tabsContainer = UIView()
        tabsContainer.backgroundColor = UIColor.clearColor()
        tabsScrollView.addSubview(tabsContainer)
        tabsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        views["container"] = tabsContainer
        tabsScrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[container(tabsScroll)]-0-|", options: [], metrics: nil, views: views))
        
        
        var maxWidth: CGFloat = 0.0
        var totalWidth: CGFloat = 0.0
        let realTabHeight = tabsHeight * UIScreen.mainScreen().scale
        var calculatedWidths = [CGFloat]()
        for button in tabButtons {
            var size = CGSizeZero
            if let image = button.imageForState(.Normal) where image.size.height > realTabHeight,
                let scaledImage = image.imageByResizeToHeight(realTabHeight) {
                button.setImage(scaledImage, forState: .Normal)
                size = scaledImage.size
            }
            else {
                button.titleLabel?.font = tabFont
                var backgroundToAddBack = [UIImageView]()
                for subview in button.subviews {
                    if let iv = subview as? UIImageView {
                        if let image = iv.image where image.size.height > realTabHeight,
                            let scaledImage = image.imageByResizeToHeight(realTabHeight) {
                                iv.image = scaledImage
                        }
                        if let label = button.titleLabel,
                            let _ = label.text { // It's a background image
                               backgroundToAddBack.insert(iv, atIndex: 0)
                               iv.removeFromSuperview() // Remove to calculate size more precisely
                        }
                    }
                }
                size = button.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                for iv in backgroundToAddBack {
                    addTabView(iv, toButton: button, selected: iv.tag == FRPageViewController.FRPVC_SELECTED_TAB_VIEW_TAG)
                }
            }
            size.width += 8.0
            maxWidth = max(maxWidth, size.width)
            calculatedWidths.append(size.width)
            totalWidth += size.width
        }
        switch tabWidthOption {
        case .EqualWidth(let minWidth):
            maxWidth = max(maxWidth, minWidth)
            totalWidth = maxWidth * CGFloat(numberOfPages)
            break
        case .ProportionalWidth:
            break
        }
        
        
        var leftButton: UIButton?
        for i in 0...numberOfPages - 1 {
            let button = tabButtons[i]
            button.addTarget(self, action: "didTapOnTabButton:", forControlEvents: .TouchUpInside)
            button.tag = FRPageViewController.FRPVC_BUTTON_TAG + i

            updateTabButtonState(button)
            tabsContainer.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            var ratio : CGFloat = 0
            switch tabWidthOption {
            case .EqualWidth(_):
                ratio = 1 / CGFloat(numberOfPages)
                break
            case .ProportionalWidth:
                ratio =  calculatedWidths[i] / totalWidth
                break
            }
       
            tabsContainer.addConstraint(NSLayoutConstraint(item: button, attribute: .Width, relatedBy: .Equal, toItem: tabsContainer, attribute: .Width, multiplier: ratio, constant: 0.0))
            
            if let lb = leftButton {
                tabsContainer.addConstraint(NSLayoutConstraint(item: button, attribute: .Leading, relatedBy: .Equal, toItem: lb, attribute: .Trailing, multiplier: 1.0, constant: 0.0))
            }
            else {
                tabsContainer.addConstraint(NSLayoutConstraint(item: button, attribute: .Leading, relatedBy: .Equal, toItem: tabsContainer, attribute: .Leading, multiplier: 1.0, constant: 0.0))
            }
            
            tabsContainer.addConstraint(NSLayoutConstraint(item: button, attribute: .Top, relatedBy: .Equal, toItem: tabsContainer, attribute: .Top, multiplier: 1.0, constant: 0.0))
            tabsContainer.addConstraint(NSLayoutConstraint(item: button, attribute: .Bottom, relatedBy: .Equal, toItem: tabsContainer, attribute: .Bottom, multiplier: 1.0, constant: -highlighterHeight-tabContentDividerHeight))
            
            leftButton = button
        }
        
        metrics["tabWidth"] = totalWidth
        tabsScrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[container(tabWidth@751)]-0-|", options: [], metrics: metrics, views: views))
        view.addConstraint(NSLayoutConstraint(item: tabsContainer, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: view, attribute: .Width, multiplier: 1.0, constant: 0.0))
        
        if highlighterHeight > 0 {
            highlighter = UIView()
            highlighter!.backgroundColor = tintColor
            tabsContainer.addSubview(highlighter!)
            highlighter!.translatesAutoresizingMaskIntoConstraints = false
            let metrics = ["height": highlighterHeight,
                            "dividerHeight": tabContentDividerHeight]
            let views = ["highlighter" : highlighter!]
            tabsContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[highlighter(height)]-dividerHeight-|", options: [], metrics: metrics, views: views))
            let selectedButton = tabButtons[currentIndex]
            let highlighterLeadingContraint = NSLayoutConstraint(item: highlighter!, attribute: .Leading, relatedBy: .Equal, toItem: selectedButton, attribute: .Leading, multiplier: 1.0, constant: 0.0)
            let highlighterWidthContraint = NSLayoutConstraint(item: highlighter!, attribute: .Width, relatedBy: .Equal, toItem: selectedButton, attribute: .Width, multiplier: 1.0, constant: 0.0)
            highlighterContraints = [highlighterWidthContraint, highlighterLeadingContraint]
            tabsContainer.addConstraints(highlighterContraints!)
        }
        
        if tabContentDividerHeight > 0 {
            dividerView = UIView()
            dividerView!.backgroundColor = tabContentDividerColor
            tabsContainer.addSubview(dividerView!)
            dividerView!.translatesAutoresizingMaskIntoConstraints = false
            let metrics = ["dividerHeight": tabContentDividerHeight]
            let views = ["divider" : dividerView!]
            tabsContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[divider(dividerHeight)]-0-|", options: [], metrics: metrics, views: views))
            tabsContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[divider]-0-|", options: [], metrics: metrics, views: views))
        }
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
        
        currentViewController = datasource?.viewControllerAtIndex(currentIndex, pageViewController: self)
        if let vc = currentViewController {
            addChildViewController(vc)
            middleViewContainer.addSubview(vc.view)
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            let views = ["page": vc.view]
            middleViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
            middleViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        }
        
        leftViewController = datasource?.viewControllerAtIndex(currentIndex-1, pageViewController: self)
        if let vc = leftViewController {
            addChildViewController(vc)
            leftViewContainer.addSubview(vc.view)
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            let views = ["page": vc.view]
            leftViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
            leftViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        }
        
        rightViewController = datasource?.viewControllerAtIndex(currentIndex+1, pageViewController: self)
        if let vc = rightViewController {
            addChildViewController(vc)
            rightViewContainer.addSubview(vc.view)
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            let views = ["page": vc.view]
            rightViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
            rightViewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        }
        
        view.updateConstraintsIfNeeded()
        view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutContentViews(false)
    }
    
    // MARK: - Layout views
    private func addTabViews(tabViews: [UIView], selected: Bool, minimumWidth: CGFloat = 0) {
        if tabViews.count == 0 {
            return
        }
        
        for i in 0...tabViews.count - 1 {
            let tview = tabViews[i]
            tview.clipsToBounds = true
            
            var button: UIButton!
            if (i < tabButtons.count) {
                button = tabButtons[i]
            }
            else {
                button = UIButton(type: .Custom)
                tabButtons.append(button)
            }
            addTabView(tview, toButton: button, selected: selected, minimumWidth: minimumWidth)
        }
    }
    
    private func addTabView(tview: UIView, toButton button: UIButton, selected: Bool, minimumWidth: CGFloat = 0) {
        tview.tag = selected ? FRPageViewController.FRPVC_SELECTED_TAB_VIEW_TAG : FRPageViewController.FRPVC_UNSELECTED_TAB_VIEW_TAG
        button.addSubview(tview)
        tview.translatesAutoresizingMaskIntoConstraints = false
        let views = ["view" : tview]
        let metrics = ["minWidth" : minimumWidth]
        button.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view(>=minWidth)]-0-|", options: [], metrics: metrics, views: views))
        button.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options: [], metrics: metrics, views: views))
        button.sendSubviewToBack(tview)
        tview.userInteractionEnabled = false
        tview.exclusiveTouch = false

    }
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
    
    private func updateTabButtonState(button: UIButton, selectedIndex: Int? = nil) {
        let index = button.tag - FRPageViewController.FRPVC_BUTTON_TAG
        let selected = index == (selectedIndex ?? currentIndex)
        let color = selected ? tintColor : subTintColor
        button.setTitleColor(color, forState: .Normal)
        button.tintColor = color
        button.backgroundColor = selected ? selectedTabBackgroundColor : unselectedTabBackgroundColor
        button.viewWithTag(FRPageViewController.FRPVC_SELECTED_TAB_VIEW_TAG)?.alpha = selected ? 1.0 : 0.0
        button.viewWithTag(FRPageViewController.FRPVC_UNSELECTED_TAB_VIEW_TAG)?.alpha = selected ? 0.0 : 1.0
    }
    
    // MARK: -
    
    func moveToPageAtIndex(newIndex: Int) {
        assert(newIndex >= 0 && newIndex < numberOfPages, "Invalid page index")
        
        if (newIndex == currentIndex) {
            return
        }
        
        let forward = oldIndex < newIndex
        
        if (forward) {
            rightViewController = datasource?.viewControllerAtIndex(newIndex, pageViewController: self)
        }
        else {
            leftViewController = datasource?.viewControllerAtIndex(newIndex, pageViewController: self)
        }
        
        isTabButtonTapped = true
        oldIndex = currentIndex
        scrollAnimated(true, forward: forward) {
            self.currentIndex = newIndex
            self.layoutContentViews(false)
        }
        updateTabsScroll(newIndex)
    }
    
    private var isTabButtonTapped = false
    func didTapOnTabButton(button: UIButton) {
        let newIndex = button.tag - FRPageViewController.FRPVC_BUTTON_TAG
        if currentIndex == newIndex {
            return
        }
        
        moveToPageAtIndex(newIndex)
    }
    
    // MARK: Transit views
    
    func updateTabsScroll(newIndex: Int) {
        let selectedButton = tabButtons[newIndex]
        updateTabButtonState(selectedButton, selectedIndex: newIndex)
        let oldButton = tabButtons[oldIndex]
        updateTabButtonState(oldButton, selectedIndex: newIndex)
        
        var tabFrame = selectedButton.frame
        
        if (oldIndex < newIndex && newIndex < self.numberOfPages - 1) {
            tabFrame.size.width += 30;
        }
        else if (oldIndex > newIndex && newIndex > 0) {
            tabFrame.origin.x -= 30;
        }
        tabsScrollView.scrollRectToVisible(tabFrame, animated: true)
        if let hl = highlighter {
            let highlighterLeadingContraint = NSLayoutConstraint(item: hl, attribute: .Leading, relatedBy: .Equal, toItem: selectedButton, attribute: .Leading, multiplier: 1.0, constant: 0.0)
            let highlighterWidthContraint = NSLayoutConstraint(item: hl, attribute: .Width, relatedBy: .Equal, toItem: selectedButton, attribute: .Width, multiplier: 1.0, constant: 0.0)
            let container = tabsScrollView.subviews[0]
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                if let hlc = self.highlighterContraints {
                    container.removeConstraints(hlc)
                }
                self.highlighterContraints = [highlighterWidthContraint, highlighterLeadingContraint]
                container.addConstraints(self.highlighterContraints!)
                container.layoutIfNeeded()
            })
        }
        isTabButtonTapped = false
    }
    
    func scrollAnimated(animated: Bool, forward: Bool, completion: ()->()) {
        if let _ = (forward ? rightViewController : leftViewController) {
            let xOffset = forward ? contentScrollView.bounds.width * 2 : 0
            if animated && scrollingState == FRPVCContentScrollState.None {
                scrollingState = .Scrolling(forward)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    // MARK: - Scroll view delegate
 
    private var scrollingState = FRPVCContentScrollState.None
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if isTabButtonTapped {
            return
        }
        if (scrollView.tag == FRPageViewController.FRPVC_CONTENT_SCROLL_TAG) {
            let viewWidth = scrollView.bounds.size.width
            let progress = (scrollView.contentOffset.x - viewWidth) / viewWidth
            if progress != 0 {
                let forward = progress > 0
                if let dest = (forward ? rightViewController : leftViewController) {
                    scrollingState = FRPVCContentScrollState.Scrolling(forward)
                    if (abs(progress) < 1) {
                        let seeingIndex = forward ? currentIndex + 1 : currentIndex - 1
                        if (seeingIndex < numberOfPages && seeingIndex >= 0) {
                            if let (tred, tgreen, tblue, talpha) = tintColor.colorComponents(),
                                let (sred, sgreen, sblue, salpha) = subTintColor.colorComponents() {
                                    let newAlpha = salpha + (talpha - salpha) * abs(progress)
                                    let newRed = sred + (tred - sred) * abs(progress)
                                    let newBlue = sblue + (tblue - sblue) * abs(progress)
                                    let newGreen = sgreen + (tgreen - sgreen) * abs(progress)
                                    let color = UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
                                    tabButtons[seeingIndex].setTitleColor(color, forState: .Normal)
                                    tabButtons[seeingIndex].tintColor = color
                            }
                            
                            if let (tred, tgreen, tblue, talpha) = selectedTabBackgroundColor.colorComponents(),
                                let (sred, sgreen, sblue, salpha) = unselectedTabBackgroundColor.colorComponents() {
                                    let newAlpha = salpha + (talpha - salpha) * abs(progress)
                                    let newRed = sred + (tred - sred) * abs(progress)
                                    let newBlue = sblue + (tblue - sblue) * abs(progress)
                                    let newGreen = sgreen + (tgreen - sgreen) * abs(progress)
                                    tabButtons[seeingIndex].backgroundColor = UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
                            }
                            
                            tabButtons[seeingIndex].viewWithTag(FRPageViewController.FRPVC_SELECTED_TAB_VIEW_TAG)?.alpha = abs(progress)
                        }
                        
                    }
                    
                    if (abs(progress) >= 1) {
                        didScrollTo(dest, animated: false)
                    }
                }
            }
        }
    }
    
    
    private func didScrollTo(destinatedViewController: UIViewController?, animated: Bool) {
        scrollingState = .None
        if destinatedViewController == currentViewController {
            updateTabsScroll(currentIndex)
            return
        }
        else if (destinatedViewController == rightViewController) {
            currentIndex++
        } else if (destinatedViewController == leftViewController) {
            currentIndex--
        }
        layoutContentViews(animated)
        updateTabsScroll(currentIndex)
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
