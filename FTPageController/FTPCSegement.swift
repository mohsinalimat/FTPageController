//
//  FTPCSegement.swift
//  FTPageController
//
//  Created by liufengting on 2018/8/8.
//

import UIKit

open class FTPCTitleModel: NSObject {
    
    public var title: String = ""
    public var font: UIFont = UIFont.systemFont(ofSize: 10.0)
    public var titleWidth: CGFloat = 0.0
    
    public convenience init(title: String?, font: UIFont) {
        self.init()
        self.title = (title != nil && (title?.count)! > 0) ? title! : "Title"
        self.font = font
        self.calculateTitleWidth()
    }
    
    private func calculateTitleWidth() {
        if self.title.count <= 0 || self.font.pointSize < 0 {
            return
        }
        let size = self.title.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 100.0), options: .usesLineFragmentOrigin, attributes:[NSAttributedString.Key.font : self.font] , context: nil)
        self.titleWidth = size.width
    }
    
}

public protocol FTPCSegementDelegate: NSObjectProtocol {
    
    func ftPCSegement(segement: FTPCSegement, didSelect page: NSInteger)
    
}

open class FTPCSegement: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet var collectionView: UICollectionView!
    public var indicator: UIView = UIView()
    public weak var delegate: FTPCSegementDelegate?
    public weak var segementConfig: FTPCSegementConfig!
    public weak var indicatorConfig: FTPCIndicatorConfig!
    public var selectedPage: NSInteger = 0
    public var titleArray: [FTPCTitleModel] = []

    override open func awakeFromNib() {
        super.awakeFromNib()

        self.collectionView.insertSubview(self.indicator, at: 0)
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        }
        self.collectionView.register(UINib(nibName: "FTPCSegementCell", bundle: Bundle(for: self.classForCoder)), forCellWithReuseIdentifier: FTPCSegementCell.identifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.reloadData()
    }
    
    public func setupWithTitles(titles: [FTPCTitleModel], config: FTPCConfig, delegate: FTPCSegementDelegate?, selectedPage: NSInteger)  {
        self.titleArray = titles
        self.segementConfig = config.segementConfig
        self.indicatorConfig = config.indicatorConfig
        self.delegate = delegate
        self.selectedPage = selectedPage
        self.frame = self.segementConfig.frame
        self.indicator.backgroundColor = self.indicatorConfig.color
    }


    public func selectPage(page: NSInteger, animated: Bool) {
        self.selectedPage = page
        for cell in self.collectionView.visibleCells {
            if let realCell: FTPCSegementCell = cell as? FTPCSegementCell {
                realCell.setSelected(selected: realCell.indexPath.item == page)
            }
        }
        self.collectionView.scrollToItem(at: IndexPath(item: page, section: 0), at: UICollectionViewScrollPosition.right, animated: animated)
        self.scrollIndictorToPage(page: page, animated: animated)
    }
    
    func scrollIndictorToPage(page: NSInteger, animated: Bool) {
        let rect = self.frameForIndicatorAtIndex(index: page)
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.indicator.frame = rect
            }
        } else {
            self.indicator.frame = rect
        }
    }
    
    public func handleTransition(fromPage: NSInteger, toPage: NSInteger, percent: CGFloat) {
//        self.cellAtIndex(index: fromPage)?.handleTransition(percent: isLeftToRight ? percent : (1 - percent), isLeftToRight: isLeftToRight)
//        self.cellAtIndex(index: toPage)?.handleTransition(percent: isLeftToRight ? (1 - percent) : percent, isLeftToRight: isLeftToRight)
        self.cellAtIndex(index: fromPage)?.handleTransition(percent: percent)
        self.cellAtIndex(index: toPage)?.handleTransition(percent:(1.0 - percent))
    }
    
    func cellAtIndex(index: NSInteger) -> FTPCSegementCell? {
        return self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTPCSegementCell
    }
    
    // MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.widthForItemAtIndex(index: indexPath.item), height: self.bounds.size.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.titleArray.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : FTPCSegementCell = collectionView.dequeueReusableCell(withReuseIdentifier: FTPCSegementCell.identifier, for: indexPath) as! FTPCSegementCell
        cell.setupWith(titleModel: self.titleArray[indexPath.item], segementConfig: self.segementConfig, indexPath: indexPath, selected: (indexPath.item == self.selectedPage))
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.handleCellTapAtIndexPath(indexPath: indexPath)
    }
    
    func handleCellTapAtIndexPath(indexPath: IndexPath) {
        if self.selectedPage != indexPath.item {
            self.selectPage(page: indexPath.item, animated: true)
            if self.delegate != nil {
                self.delegate!.ftPCSegement(segement: self, didSelect: indexPath.item)
            }
        }
    }
    
    func titleWidthForItemAtIndex(index: NSInteger) -> CGFloat {
        return self.titleArray[index].titleWidth
    }
    
    func widthForItemAtIndex(index: NSInteger) -> CGFloat {
        var width: CGFloat = 0.0
        switch self.segementConfig.mode {
        case .auto:
            width = (self.titleArray[index].titleWidth + self.segementConfig.titleMargin * 2.0)
        case .fixed:
            width = self.segementConfig.fixedWidth
        case .fill:
            width = self.bounds.size.width / CGFloat(self.segementConfig.columns)
        }
        return width
    }
    
    func xPositionForIndicatorAtIndex(index: NSInteger) -> CGFloat {
        var x: CGFloat = 0
        if index > 0 {
            for i in 0...(index-1) {
                x += self.widthForItemAtIndex(index: i)
            }
        }
        let itemWidth = self.widthForItemAtIndex(index: index)
        let indicatorWidth = self.widthForIndicatorAtIndex(index: index)
        x += (itemWidth - indicatorWidth)/2.0
        return x
    }
    
    func yPositionForIndicatorAtIndex(index: NSInteger) -> CGFloat {
        var y: CGFloat = 0
        switch self.indicatorConfig.position {
        case .top:
            y = 0
        case .center:
            y = (self.bounds.size.height - self.indicatorConfig.height)/2
        case .bottom:
            y = self.bounds.size.height - self.indicatorConfig.height
        }
        return y
    }
    
    func widthForIndicatorAtIndex(index: NSInteger) -> CGFloat {
        var width: CGFloat = 0.0
        switch self.indicatorConfig.mode {
        case .auto:
            width = self.titleWidthForItemAtIndex(index: index) - (self.indicatorConfig.horizontalOffsetToTitle * 2.0)
        case .fill:
            width = self.widthForItemAtIndex(index: index)
        case .fixed:
            width = self.indicatorConfig.width
        }
        return width
    }
    
    func heightForIndicatorAtIndex(index: NSInteger) -> CGFloat {
        return self.indicatorConfig.height
    }
    
    func frameForIndicatorAtIndex(index: NSInteger) -> CGRect {
        return CGRect(x: self.xPositionForIndicatorAtIndex(index: index),
                      y: self.yPositionForIndicatorAtIndex(index: index),
                      width: self.widthForIndicatorAtIndex(index: index),
                      height: self.heightForIndicatorAtIndex(index: index))
    }
    

}
