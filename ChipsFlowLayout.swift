//
//  ChipsFlowLayout.swift
//  CollectionView Layout Practice
//
//  Created by Murtaza Mehmood on 05/03/2025.
//

import UIKit

/// Protocol defining the delegate methods for `ChipsFlowLayout`.
protocol ChipsFlowLayoutDelegate: AnyObject {
    /// Returns the size for the header in a specific section.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: ChipsFlowLayout, heightForHeaderInSection section: Int) -> CGSize
    
    /// Returns the size for a specific item at an index path.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: ChipsFlowLayout, sizeForItem indexPath: IndexPath) -> CGSize
    
    /// Returns the insets for a section.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: ChipsFlowLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    
    /// Returns the spacing between rows in a section.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: ChipsFlowLayout, rowSpacing section: Int) -> CGFloat
    
    /// Returns the spacing between columns in a section.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: ChipsFlowLayout, columnSpacing section: Int) -> CGFloat
    
    /// Notifies the delegate of the total content height after layout calculations.
    func collectionView(_ collectionView: UICollectionView, layout chipsLayout: ChipsFlowLayout, height: CGFloat)
}

/// Custom `UICollectionViewLayout` for managing chips-style flow layout.
class ChipsFlowLayout: UICollectionViewLayout {
    
    // MARK: - Properties
    weak var delegate: ChipsFlowLayoutDelegate?
    
    /// Cache for header attributes to avoid recalculations.
    private var headerCache: [UICollectionViewLayoutAttributes] = []
    /// Cache for item attributes to improve layout performance.
    private var itemCache: [UICollectionViewLayoutAttributes] = []
    
    /// Content height tracking variable.
    private var contentHeight: CGFloat = 0.0
    /// Computed property for content width based on collection view bounds.
    private var contentWidth: CGFloat {
        return collectionView?.bounds.width ?? 0
    }
    
    /// Returns the total content size of the layout.
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
        
    }
    
    override func prepare() {
        // Reset caches and layout values before layout calculation.
        headerCache.removeAll()
        itemCache.removeAll()
        var xOffset: CGFloat = 0.0
        var yOffset: CGFloat = 0.0
        guard let collectionView = collectionView else { return }
        
        for section in 0..<collectionView.numberOfSections {
            
            let headerSize = delegate?.collectionView(collectionView, layout: self, heightForHeaderInSection: section) ?? .zero
            let contentInset = delegate?.collectionView(collectionView, layout: self, insetForSectionAt: section) ?? .zero
            let columnSpacing = delegate?.collectionView(collectionView, layout: self, columnSpacing: section) ?? .zero
            let rowSpacing = delegate?.collectionView(collectionView, layout: self, rowSpacing: section) ?? .zero
            
            // Handle header layout
            let headerFrame = CGRect(x: 0, y: yOffset, width: contentWidth, height: headerSize.height)
            let headerAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
            headerAttribute.frame = headerFrame
            headerCache.append(headerAttribute)
            
            yOffset += headerSize.height
            contentHeight += headerSize.height
            
            var itemSize: CGSize = .zero
            
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(row: item, section: section)
                itemSize = delegate?.collectionView(collectionView, layout: self, sizeForItem: indexPath) ?? .zero
                
                if item == 0 {
                    // Handle items layout
                    xOffset += contentInset.left
                    yOffset += contentInset.top
                }
                
                // Check if item fits in current row, otherwise move to the next row.
                if xOffset + itemSize.width + columnSpacing > contentWidth {
                    xOffset = contentInset.left
                    yOffset += itemSize.height + rowSpacing
                    contentHeight = yOffset
                }
                
                let frame: CGRect = CGRect(x: xOffset,
                                           y: yOffset,
                                           width: itemSize.width,
                                           height: itemSize.height)
                
                let itemAttribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                itemAttribute.frame = frame
                itemCache.append(itemAttribute)
                xOffset += itemSize.width + columnSpacing
            }
            
            // Adjust for section bottom inset
            xOffset = 0.0
            let updateContent = itemSize.height + contentInset.bottom
            yOffset += updateContent
            contentHeight += updateContent
        }
        // Notify delegate about the total content height.
        delegate?.collectionView(collectionView, layout: self, height: contentHeight)
    }
    
    // MARK: - Layout Attribute Handling
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)
        var attributes: [UICollectionViewLayoutAttributes] = []
        let header = headerCache.filter { $0.frame.intersects(rect) }
        let items = itemCache.filter { $0.frame.intersects(rect) }
        attributes.append(contentsOf: header)
        attributes.append(contentsOf: items)
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemCache[indexPath.item]
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.initialLayoutAttributesForAppearingDecorationElement(ofKind: elementKind, at: indexPath)
        return headerCache[indexPath.section]
    }
}
