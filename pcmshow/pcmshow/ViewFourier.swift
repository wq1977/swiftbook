//
//  ViewFourier.swift
//  pcmshow
//
//  Created by 王强 on 14/11/24.
//  Copyright (c) 2014年 王强. All rights reserved.
//

import UIKit

class ViewFourier: UIView {

    var dataSource:ViewFourierDataSource?
    
    override func drawRect(rect: CGRect) {
        let 频率颜色 = UIColor.redColor().CGColor
        let ctx = UIGraphicsGetCurrentContext()
        CGContextClearRect(ctx, rect)
        if dataSource == nil { return }
        if let 原始数据 = dataSource!.傅立叶数据提供(self){
            let 频率宽度间隔比 = 2.0
            let 最小单位 = Double(rect.size.width) / (Double(原始数据.count)*(频率宽度间隔比 + 1.0))
            for i in 0..<原始数据.count{
                CGContextSetFillColorWithColor(ctx, 频率颜色)
                let 频率高度 = rect.size.height * CGFloat(原始数据[i]<0 ? 0 : 原始数据[i]) / CGFloat(100)
                CGContextFillRect(ctx, CGRectMake(CGFloat(i)*CGFloat(最小单位)*CGFloat(频率宽度间隔比 + 1.0),
                    rect.size.height - 频率高度, CGFloat(最小单位)*CGFloat(频率宽度间隔比),频率高度))
            }
        }
    }
}
