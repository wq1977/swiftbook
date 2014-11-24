//
//  ViewFourierDataSource.swift
//  pcmshow
//
//  Created by 王强 on 14/11/24.
//  Copyright (c) 2014年 王强. All rights reserved.
//

protocol ViewFourierDataSource {
    func 傅立叶数据提供(视图:ViewFourier) -> [Float]?
}
