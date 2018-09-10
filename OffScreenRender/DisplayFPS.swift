//
//  DisplayFPS.swift
//  AsynDisplay
//
//  Created by wanghuiguang on 2018/8/28.
//  Copyright © 2018年 wanghuiguang. All rights reserved.
//

import UIKit

class SYFPSObject: NSObject {
    var fpsLabel: UILabel = { ()->UILabel in
        let fpsLabel = UILabel()
        fpsLabel.backgroundColor = .lightGray
        fpsLabel.textColor = .black
        return fpsLabel
    }()
    
    var link:CADisplayLink?
    var targetLinkBlock:((Double)->())?
    
    init(targetLinkBlock:@escaping (Double)->()) {
        super.init()
        
        self.targetLinkBlock = targetLinkBlock
        
        weak var weakSelf = self
        let link =  CADisplayLink.init(target: weakSelf!, selector: #selector(linkFps(link:)))
        link.add(to: RunLoop.current, forMode: .commonModes)
        self.link = link
    }
    
    private var _timeD:Double = 0
    private var _count:Int = 0
    @objc func linkFps( link: CADisplayLink) {
        let timestamp = link.timestamp
        _count += 1
        if _timeD <= 0 {
            _timeD = timestamp
            return
        }
        
        let timess = timestamp - _timeD
        if timess < 1.1 {
            return
        }
        
        let num = Double(_count)/timess
        _timeD = timestamp
        _count = 0
        
        guard let block = self.targetLinkBlock else {return}
        block(num)
    }
}

extension UIView {
    var fps: SYFPSObject? {
        get {
            return (objc_getAssociatedObject(self, UnsafeRawPointer.init(bitPattern:"&SYFPSObject".hashValue)!) as? SYFPSObject)
        }
        
        set {
            objc_setAssociatedObject(self, UnsafeRawPointer.init(bitPattern:"&SYFPSObject".hashValue)!, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc func addFPS(showFrame frame:CGRect) {
        self.fps = SYFPSObject.init(targetLinkBlock: { (number) in
            DispatchQueue.main.async {
                self.fps?.fpsLabel.text = String(format: "%.2f", number)
            }
        })
        self.fps?.fpsLabel.frame = frame
        if let label = self.fps?.fpsLabel {
            self.addSubview(label)
            self.bringSubview(toFront: label)
        }
    }
}
