//
//  FRPVCTabCell.swift
//  FRPageViewControllerDemo
//
//  Created by Do Thi Hong Ha on 2/29/16.
//  Copyright © 2016 Yotel. All rights reserved.
//

import UIKit

class FRPVCTabCell: UICollectionViewCell {
    private let contentContainer = UIView()
    private var contentMinWidthConstraint: NSLayoutConstraint?
    private var backgroundImageView: UIImageView?
    
    var minWidth : CGFloat = 16 {
        didSet {
            contentMinWidthConstraint?.constant = minWidth
        }
    }
    
    var highlightTintColor: UIColor = UIColor.whiteColor() {
        didSet {
            if (selected) {
                contentContainer.tintColor = highlightTintColor
            }
        }
    }
    
    var normalTintColor: UIColor = UIColor.lightGrayColor() {
        didSet {
            if (!selected) {
                contentContainer.tintColor = normalTintColor
            }
        }
    }
    
    var highlightBackgroundColor: UIColor? {
        didSet {
            self.backgroundColor = selected ? highlightTintColor : self.backgroundColor
        }
    }
    
    var normalBackgroundColor: UIColor? {
        didSet {
            self.backgroundColor = selected ? self.backgroundColor : normalBackgroundColor
        }
    }
    
    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            super.selected = newValue
            backgroundColor = newValue ? highlightBackgroundColor : normalBackgroundColor
            contentContainer.tintColor = newValue ? highlightTintColor : normalTintColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(contentContainer)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.fr_fillSuperView()
        backgroundColor = UIColor.clearColor()
        contentMinWidthConstraint = NSLayoutConstraint(item: contentContainer, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minWidth)
        contentView.addConstraint(contentMinWidthConstraint!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func requiredCellWidth() -> CGFloat {
        setNeedsLayout()
        layoutIfNeeded()
        return ceil(contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).width) + 1.0
    }
}

class FRVCTabRenderedIconCell: FRPVCTabCell {
    private let tabImageView = UIImageView()
    
    private var imageYMarginConstraints = [NSLayoutConstraint]()
    var imageYMargin: CGFloat = 8.0 {
        didSet {
            for c in imageYMarginConstraints {
                c.constant = imageYMargin
            }
        }
    }
    
    private var imageXMarginConstraints = [NSLayoutConstraint]()
    var imageXMargin: CGFloat = 8.0 {
        didSet {
            for c in imageXMarginConstraints {
                c.constant = imageXMargin
            }
            minWidth = max(minWidth, imageXMargin * 2)
        }
    }
    
    private var imageWHRatioConstraint: NSLayoutConstraint!
    private var currentRatio: CGFloat = 1
    
    var image: UIImage? {
        didSet {
            tabImageView.image = image?.imageWithRenderingMode(.AlwaysTemplate)
            if imageWHRatioConstraint != nil {
                var newRatio : CGFloat = 1
                if let i = image {
                    newRatio = i.size.width / i.size.height
                }
                
                if (currentRatio != newRatio) {
                    currentRatio = newRatio
                    contentContainer.removeConstraint(imageWHRatioConstraint)
                    imageWHRatioConstraint = NSLayoutConstraint(item: tabImageView, attribute: .Width, relatedBy: .Equal, toItem: tabImageView, attribute: .Height, multiplier: currentRatio, constant: 0)
                    imageWHRatioConstraint.priority = 999
                    contentContainer.addConstraint(imageWHRatioConstraint)
                }
            }
        }
    }
    
    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            super.selected = newValue
            tabImageView.tintColor = newValue ? highlightTintColor : normalTintColor
        }
    }
    
    override var normalTintColor: UIColor {
        set(newValue) {
            super.normalTintColor = newValue
            tabImageView.tintColor = selected ? highlightTintColor : newValue
        }
        get {
            return super.normalTintColor
        }
    }
    
    override var highlightTintColor: UIColor {
        set(newValue) {
            super.highlightTintColor = newValue
            tabImageView.tintColor = selected ? newValue : normalTintColor
        }
        get {
            return super.highlightTintColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentContainer.addSubview(tabImageView)
        tabImageView.translatesAutoresizingMaskIntoConstraints = false
        imageYMarginConstraints = tabImageView.fr_snap([FRALPosition.Top, FRALPosition.Bottom], padding: imageYMargin, toView: contentContainer)
        imageXMarginConstraints = tabImageView.fr_snap([FRALPosition.Left, FRALPosition.Right], padding: imageXMargin, toView: contentContainer)
        contentContainer.addConstraints(imageXMarginConstraints)
        contentContainer.addConstraints(imageYMarginConstraints)
        tabImageView.contentMode = .ScaleAspectFit
        imageWHRatioConstraint = NSLayoutConstraint(item: tabImageView, attribute: .Width, relatedBy: .Equal, toItem: tabImageView, attribute: .Height, multiplier: currentRatio, constant: 0)
        imageWHRatioConstraint.priority = 999
        contentContainer.addConstraint(imageWHRatioConstraint)
    }
    
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FRPVCTabIconCell: FRVCTabRenderedIconCell {

    var highlightImage: UIImage? {
        didSet {
            if (selected) {
                tabImageView.image = highlightImage
            }
        }
    }
    
    var normalImage: UIImage? {
        didSet {
            if (!selected) {
                tabImageView.image = normalImage
            }
        }
    }
    
    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            super.selected = newValue
            tabImageView.image = newValue ? highlightImage : normalImage
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FRPVCTabTitleCell: FRPVCTabCell {
    private let tabTitleLabel = UILabel()
    
    private var labelYMarginConstraints = [NSLayoutConstraint]()
    var labelYMargin: CGFloat = 8.0 {
        didSet {
            for c in labelYMarginConstraints {
                c.constant = labelYMargin
            }
        }
    }
    
    private var labelXMarginConstraints = [NSLayoutConstraint]()
    var labelXMargin: CGFloat = 8.0 {
        didSet {
            for c in labelXMarginConstraints {
                c.constant = labelXMargin
            }
            minWidth = max(minWidth, labelXMargin * 2)
            tabTitleLabel.preferredMaxLayoutWidth = frame.size.width - labelXMargin * 2
        }
    }
    
    var title : String {
        get {
            return tabTitleLabel.text ?? ""
        }
        set {
            tabTitleLabel.text = newValue
        }
    }

    var font: UIFont {
        get {
            return tabTitleLabel.font
        }
        set {
            tabTitleLabel.font = newValue
        }
    }
    
    override var selected: Bool {
        set(newValue) {
            super.selected = newValue
            tabTitleLabel.textColor = newValue ? highlightTintColor : normalTintColor
        }
        get {
            return super.selected
        }
    }
    
    override var normalTintColor: UIColor {
        set(newValue) {
            super.normalTintColor = newValue
            tabTitleLabel.textColor = selected ? highlightTintColor : newValue
        }
        get {
            return super.normalTintColor
        }
    }
    
    override var highlightTintColor: UIColor {
        set(newValue) {
            super.highlightTintColor = newValue
            tabTitleLabel.textColor = selected ? newValue : normalTintColor
        }
        get {
            return super.highlightTintColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentContainer.addSubview(tabTitleLabel)
        tabTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        labelYMarginConstraints = tabTitleLabel.fr_snap([FRALPosition.Top, FRALPosition.Bottom], padding: labelYMargin, toView: contentContainer)
        labelXMarginConstraints = tabTitleLabel.fr_snap([FRALPosition.Left, FRALPosition.Right], padding: labelXMargin, toView: contentContainer)
        contentContainer.addConstraints(labelXMarginConstraints)
        contentContainer.addConstraints(labelYMarginConstraints)
        tabTitleLabel.preferredMaxLayoutWidth = frame.size.width - labelXMargin * 2
        tabTitleLabel.textAlignment = .Center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FRPVCTabSubviewCell: FRPVCTabCell {
    private let FRPVC_TSC_SELECTEDVIEW_TAG = 101
    private let FRPVC_TSC_UNSELECTEDVIEW_TAG = 102
    private var _selectedSubview: UIView? {
        willSet {
            contentContainer.viewWithTag(FRPVC_TSC_SELECTEDVIEW_TAG)?.removeFromSuperview()
        }
        didSet {
            if let view = _selectedSubview {
                view.tag = FRPVC_TSC_SELECTEDVIEW_TAG
                contentContainer.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = false
                contentContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: [], metrics: nil, views: ["subview": view]))
                contentContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: [], metrics: nil, views: ["subview": view]))
            }
        }
    }
    var selectedSubview: UIView? {
        get {
            return _selectedSubview
        }
        set {
            if (newValue != _selectedSubview) {
                _selectedSubview = newValue
            }
        }
    }
    
    private var _unselectedSubview: UIView? {
        willSet {
            contentContainer.viewWithTag(FRPVC_TSC_UNSELECTEDVIEW_TAG)?.removeFromSuperview()
        }
        didSet {
            if let view = _unselectedSubview {
                view.tag = FRPVC_TSC_UNSELECTEDVIEW_TAG
                contentContainer.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = false
                contentContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: [], metrics: nil, views: ["subview": view]))
                contentContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: [], metrics: nil, views: ["subview": view]))
            }
        }
    }
    
    var unselectedSubview: UIView? {
        get {
            return _unselectedSubview
        }
        set {
            if (newValue != _unselectedSubview) {
                _unselectedSubview = newValue
            }
        }
    }

    
    override var selected: Bool {
        set(newValue) {
            super.selected = newValue
            _selectedSubview?.hidden = !newValue
            _unselectedSubview?.hidden = newValue
        }
        get {
            return super.selected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}