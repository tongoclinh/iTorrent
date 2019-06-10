//
//  SegmentedProgressView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 09/06/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class SegmentedProgressView: UIView, Themed {
    var numPiecesOld = 1
    var numPieces: Int = 1
    
    private var progress: [CGFloat] = []
    
    public func setNumberOfSections(sections: Int) {
        if (numPiecesOld == sections) { return }
        
        numPiecesOld = numPieces
        progress = [CGFloat].init(repeating: 0, count: numPieces)
    }
    
    public func setProgress(progress: [Float]) {
        setProgress(progress: progress.map{ CGFloat($0) })
    }
    
    public func setProgress(progress: [CGFloat]) {
        if (self.progress == progress) { return }
        
        numPieces = progress.count
        self.progress = progress
        setNeedsDisplay()
    }
    
    public func setProgress(pieceIndex: Int, progress: Float) {
        self.progress[pieceIndex] = CGFloat(progress)
        setNeedsDisplay()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }
    
    @objc func themeUpdate() {
//        backgroundColor = Themes.current().progressBarBackground
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = true
        
//        numPieces = 4
//        progress = [0.8, 0.2, 0.9, 0.6]
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(bounds.size.height)
        context?.setStrokeColor(tintColor.cgColor)
        let pieceLength = bounds.width / CGFloat(numPieces)
        for i in 0 ..< numPieces {
            let start = CGFloat(i) * bounds.width / CGFloat(numPieces)
            context?.move(to: CGPoint(x: start, y: bounds.midY))
            context?.addLine(to: CGPoint(x: start + progress[i] * pieceLength, y: bounds.midY))
            context?.strokePath()
        }
    }
}
