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
    case CustomViews
}

class ViewController: UIViewController, FRPageViewControllerDelegate {
    
    var segmentType = SegmentType.TitlesOnly

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupPages()
    }
    
    func setupPages() {
        var pages = [UIViewController]()
        let colors = [UIColor.redColor(), UIColor.grayColor(), UIColor.blueColor(), UIColor.orangeColor(), UIColor.purpleColor(), UIColor.brownColor()]
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
//            let margins = vc.view.layoutMarginsGuide
//            //            label.heightAnchor.constraintEqualToAnchor(margins.heightAnchor, multiplier: 0.5).active = true
//            //            label.widthAnchor.constraintEqualToAnchor(margins.widthAnchor, multiplier: 0.5).active = true
//            label.centerXAnchor.constraintEqualToAnchor(margins.centerXAnchor).active = true
//            label.centerYAnchor.constraintEqualToAnchor(margins.centerYAnchor).active = true
//            label.fr_constraints([.CenterX, .CenterY])
            label.fr_layout().constraint(.CenterX).constraint(.CenterY)
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
            pageVC = FRPageViewController(viewControllers: pages, tabTitles: titles)
            pageVC.tabWidthOption = .Proportional
            break
        case .ImagesOnly:
            pageVC = FRPageViewController(viewControllers: pages, renderedTabImages: images, minTabWidth: 60, defaultIndex: 1)
            break
        case .CustomViews:
            var selectedViews = [UIView]()
            var unselectedViews = [UIView]()
            for i in 0...5 {
                let backgroundColor = pages[i].view.backgroundColor
                selectedViews.append(customViewWithTitle(titles[i], image:  UIImage(named: "SegmentIcon\(i+1)")!.imageWithRenderingMode(.AlwaysTemplate), backgroundColor: backgroundColor, isSelected: true))
                unselectedViews.append(customViewWithTitle(titles[i], image:  UIImage(named: "SegmentIcon\(i+1)")!.imageWithRenderingMode(.AlwaysTemplate), backgroundColor: backgroundColor, isSelected: false))
            }
            pageVC = FRPageViewController(viewControllers: pages, selectedTabViews: selectedViews, unselectedTabViews: unselectedViews)
            pageVC.highlighterHeight = 0.0
            pageVC.tabWidthOption = .Proportional
            break
        }
        pageVC.delegate = self
        self.addChildViewController(pageVC)
        self.view.addSubview(pageVC.view)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        pageVC.tabsBackgroundColor = UIColor.blackColor()
        let views = ["page": pageVC.view]
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[page]-0-|", options: [], metrics: nil, views: views))
        //        pageVC .didMoveToParentViewController(self)
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
        pageVC.didMoveToParentViewController(self)
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

}

