//
//  ViewController.swift
//  FRPageViewControllerDemo
//
//  Created by Do Thi Hong Ha on 1/13/16.
//  Copyright © 2016 Yotel. All rights reserved.
//

import UIKit
enum SegmentType {
    case TitlesOnly
    case ImagesOnly
    case TitlesWithBackground
    case CustomViews
}

class ViewController: UIViewController, FRPageViewControllerDataSource, FRPageViewControllerDelegate {
    var pages = [UIViewController]()
    var segmentType = SegmentType.TitlesOnly

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupPages()
    }
    
    func setupPages() {
        let colors = [UIColor.redColor(), UIColor.blackColor(), UIColor.blueColor(), UIColor.orangeColor(), UIColor.purpleColor(), UIColor.brownColor()]
        let titles = ["Sling", "Ukhidcaster", "Egouver", "Zhoemouth", "Goln", "Clagend"]
        for i in 0...colors.count-1 {
            let vc = UIViewController()
            vc.view.backgroundColor = colors[i]
            vc.title = "\(i) \(titles[i])"
            let label = UILabel()
            label.text = "\(i)"
            label.textColor = UIColor.whiteColor()
            label.font = UIFont.systemFontOfSize(50)
            vc.view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            let margins = vc.view.layoutMarginsGuide
            //            label.heightAnchor.constraintEqualToAnchor(margins.heightAnchor, multiplier: 0.5).active = true
            //            label.widthAnchor.constraintEqualToAnchor(margins.widthAnchor, multiplier: 0.5).active = true
            label.centerXAnchor.constraintEqualToAnchor(margins.centerXAnchor).active = true
            label.centerYAnchor.constraintEqualToAnchor(margins.centerYAnchor).active = true
            pages.append(vc)
        }
        
        var images = [UIImage]()
        for i in 1...6 {
            let image = UIImage(named: "SegmentIcon\(i)")?.imageWithRenderingMode(.AlwaysTemplate)
            images.append(image!)
        }
        
        var pageVC: FRPageViewController!
        switch segmentType {
        case .TitlesOnly:
            pageVC = FRPageViewController(titles: titles)
            pageVC.tabWidthOption = .ProportionalWidth
            break
        case .ImagesOnly:
            pageVC = FRPageViewController(images: images, minimumWidth: 60, displayedIndex: 1)
            break
        case .TitlesWithBackground:
            pageVC = FRPageViewController(titles: titles, selectedTabBackgroundImages: [UIImage(named: "TabDark")!], unselectedTabBackgroundImages: [UIImage(named: "TabLight")!], displayedIndex: 0)
            pageVC.tintColor = UIColor.whiteColor()
            pageVC.subTintColor = UIColor(white: 1.0, alpha: 0.5)
            pageVC.highlighterHeight = 0.0
            pageVC.tabContentDividerColor = UIColor(red: 0.0941, green: 0.2745, blue: 0.2235, alpha: 1.0) /* #184639 */
            pageVC.tabWidthOption = .ProportionalWidth
            break
        case .CustomViews:
            var selectedViews = [UIView]()
            var unselectedViews = [UIView]()
            for i in 0...5 {
                let backgroundColor = pages[i].view.backgroundColor
                selectedViews.append(customViewWithTitle(titles[i], image:  UIImage(named: "SegmentIcon\(i+1)")!.imageWithRenderingMode(.AlwaysTemplate), backgroundColor: backgroundColor, isSelected: true))
                unselectedViews.append(customViewWithTitle(titles[i], image:  UIImage(named: "SegmentIcon\(i+1)")!.imageWithRenderingMode(.AlwaysTemplate), backgroundColor: backgroundColor, isSelected: false))
            }
            pageVC = FRPageViewController(selectedTabViews: selectedViews, unselectedTabViews: unselectedViews, minimumWidth: 0.0)
            pageVC.highlighterHeight = 0.0
            pageVC.tabWidthOption = .ProportionalWidth
            break
        }
        pageVC.datasource = self
        pageVC.delegate = self
        self .addChildViewController(pageVC)
        self.view.addSubview(pageVC.view)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        let views = ["page": pageVC.view]
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        //        pageVC .didMoveToParentViewController(self)
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func customViewWithTitle(title: String, image: UIImage, backgroundColor: UIColor?, isSelected: Bool) -> UIView {
        let aview = UIView()
    
       
        let label = UILabel()
        label.text = title
        label.textColor = UIColor.whiteColor()
        if let bg = backgroundColor {
            aview.backgroundColor = isSelected ? bg : bg.colorWithAlphaComponent(0.2)
            if (!isSelected) {
                label.textColor = bg
            }
        }
        label.textAlignment = .Center
        let imageView = UIImageView(image: image)
        imageView.contentMode = .ScaleAspectFit
        imageView.tintColor = isSelected ? UIColor.whiteColor() : backgroundColor
        
        aview.addSubview(label)
        aview.addSubview(imageView)
        label.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["label": label,
                    "image": imageView]
        let metrics = ["innerPadding": 8.0]
        aview.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-4-[image(30)]-innerPadding-[label]-4-|", options: [.AlignAllTop, .AlignAllBottom], metrics: metrics, views: views))
        aview.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-5-[image(30)]", options: [], metrics: metrics, views: views))
        
        return aview
    }

    // MARK: - PageVC datasource & delegate
    func viewControllerAtIndex(index: Int, pageViewController: FRPageViewController) -> UIViewController? {
        
        if (index < 0 || index > 5) {
            return nil
        }
        return pages[index]
    }
    
    func didMoveToPage(index: Int, pageViewController: FRPageViewController) {
        if segmentType == .CustomViews {
            pageViewController.tabContentDividerColor = pages[index].view.backgroundColor ?? UIColor.clearColor()
        }
    }
    
    func didMoveToViewController(viewController: UIViewController?, pageViewController: FRPageViewController) {
        if segmentType == .CustomViews {
            pageViewController.tabContentDividerColor = viewController?.view.backgroundColor ?? UIColor.clearColor()
        }
    }
}

