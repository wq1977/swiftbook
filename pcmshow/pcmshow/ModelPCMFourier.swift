//
//  ModelPCMFourier.swift
//  pcmshow
//
//  Created by 王强 on 14/11/24.
//  Copyright (c) 2014年 王强. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

class ModelPCMFourier: NSObject,AVCaptureAudioDataOutputSampleBufferDelegate {
    
    let 通知名称 = "net.wesley.swiftbook.检测到了人声"
    
    var 最新数据 = [Float](count:Int(100), repeatedValue:0.0)
    
    func 开始录音(){
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeAudio, completionHandler:{(granted:Bool) in
            if !granted {
                println("授权使用设备失败!")
            }
            else{
                self.session.startRunning()
            }
        })
    }
    
    func 停止录音(){
        self.session.stopRunning()
    }
    
    //**********************  下面是内部代码 **********************************************
    let session = AVCaptureSession()
    
    override init() {
        super.init()
        session.sessionPreset = AVCaptureSessionPresetMedium
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)
        for dev in devices{
            let device = dev as? AVCaptureDevice
            
            let input = AVCaptureDeviceInput(device: device, error: nil)
            session.addInput(input)
            
            let out = AVCaptureAudioDataOutput()
            let audioDataOutputQueue = dispatch_queue_create("AudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
            out.setSampleBufferDelegate(self, queue: audioDataOutputQueue)
            session.addOutput(out)
            
            break
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let 样本数量 = CMSampleBufferGetNumSamples(sampleBuffer)
        let 样本数量的一半 = 样本数量 / 2

        let audiobuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
        var lengthAtOffset:UInt=0
        var totalLength:UInt=0
        var inSamples:UnsafeMutablePointer<Int8>=nil
        CMBlockBufferGetDataPointer(audiobuffer, 0, &lengthAtOffset, &totalLength, &inSamples)
        let format = CMSampleBufferGetFormatDescription(sampleBuffer)
        let desc = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        
        if desc.memory.mFormatID == AudioFormatID(kAudioFormatLinearPCM) {
            if desc.memory.mChannelsPerFrame == 1 && desc.memory.mBitsPerChannel == 16 {
                if inSamples == nil {
                    return
                }
                let samples = UnsafeMutablePointer<Float>.alloc(样本数量)
                vDSP_vflt16(UnsafePointer<Int16>(inSamples),1,samples,1,vDSP_Length(样本数量))
                let fftRadix = log2(Float(样本数量))
                let fftSetup = vDSP_create_fftsetup(vDSP_Length(fftRadix), FFTRadix(FFT_RADIX2))
                let windows = UnsafeMutablePointer<Float>.alloc(样本数量)
                vDSP_hamm_window(windows, vDSP_Length(样本数量), 0)
                vDSP_vmul(samples, 1, windows, 1, samples, 1, vDSP_Length(样本数量));
                var A=COMPLEX_SPLIT(realp: UnsafeMutablePointer<Float>.alloc(样本数量的一半), imagp: UnsafeMutablePointer<Float>.alloc(样本数量的一半))
                vDSP_ctoz(UnsafePointer<DSPComplex>(samples), 2, &A, 1, vDSP_Length(样本数量的一半))
                vDSP_fft_zrip(fftSetup, &A, 1, vDSP_Length(fftRadix), FFTDirection(FFT_FORWARD))
                var normFactor = 1.0 / Float(2 * 样本数量)
                vDSP_vsmul(A.realp, 1, &normFactor, A.realp, 1, vDSP_Length(样本数量的一半))
                vDSP_vsmul(A.imagp, 1, &normFactor, A.imagp, 1, vDSP_Length(样本数量的一半))
                A.imagp[0] = 0.0
                var fft = [Float](count:Int(样本数量), repeatedValue:0.0)
                vDSP_zvmags(&A, 1, &fft, 1, vDSP_Length(样本数量的一半))
                
                dispatch_async(dispatch_get_main_queue()){
                    for i in 0 ..< self.最新数据.count {
                        self.最新数据[i] = 10 * log10(fft[2+i])
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName(self.通知名称, object: nil)
                }
                
                vDSP_destroy_fftsetup(fftSetup)
                samples.dealloc(样本数量)
                windows.dealloc(样本数量)
                A.realp.dealloc(样本数量的一半)
                A.imagp.dealloc(样本数量的一半)
            }
        }
    }
    
}
