//
//  ViewController.swift
//  pcmshow
//
//  Created by 王强 on 14/11/24.
//  Copyright (c) 2014年 王强. All rights reserved.
//

import UIKit

class ViewController: UIViewController,ViewFourierDataSource {

    @IBOutlet weak var 傅立叶视图: ViewFourier!
    @IBOutlet weak var 控制按钮: UIButton!
    let 录音数据模型 = ModelPCMFourier()
    var 是否正在录音:Bool = false {
        didSet{
            if 是否正在录音 {
                self.控制按钮.setTitle("停止录音", forState: .Normal)
                self.录音数据模型.开始录音()
            }
            else{
                self.控制按钮.setTitle("开始录音", forState: .Normal)
                self.录音数据模型.停止录音()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.傅立叶视图.dataSource = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"收到人声检测通知:", name: 录音数据模型.通知名称, object: nil)
    }
    
    func 傅立叶数据提供(视图: ViewFourier) -> [Float]? {
        return self.录音数据模型.最新数据
    }
    
    func 收到人声检测通知(notification:NSNotification){
        dispatch_async(dispatch_get_main_queue(), {
            self.傅立叶视图.setNeedsDisplay()
        })
    }

    @IBAction func 按钮点击(sender: UIButton) {
        self.是否正在录音 = !self.是否正在录音
    }

}

