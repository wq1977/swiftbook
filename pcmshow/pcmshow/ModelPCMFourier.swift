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
    
    var 最新数据:[Float]?
    
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
    let 频率样本数 = 100
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
        let sample数量 = CMSampleBufferGetNumSamples(sampleBuffer)
        let audio缓冲 = CMSampleBufferGetDataBuffer(sampleBuffer)
        var lengthAtOffset:UInt=0
        var totalLength:UInt=0
        var inSamples:UnsafeMutablePointer<Int8>=nil
        CMBlockBufferGetDataPointer(audio缓冲, 0, &lengthAtOffset, &totalLength, &inSamples)
        let format = CMSampleBufferGetFormatDescription(sampleBuffer)
        let desc = CMAudioFormatDescriptionGetStreamBasicDescription(format)
        
        if desc.memory.mFormatID == AudioFormatID(kAudioFormatLinearPCM) {
            if desc.memory.mChannelsPerFrame == 1 && desc.memory.mBitsPerChannel == 16 {
                if inSamples == nil {
                    return
                }
                let samples = UnsafeMutablePointer<Float>.alloc(sample数量)
                vDSP_vflt16(UnsafePointer<Int16>(inSamples),1,samples,1,vDSP_Length(sample数量))
                let fftRadix = log2(Float(sample数量))
                let halfSample = sample数量 / 2
                let fftSetup = vDSP_create_fftsetup(vDSP_Length(fftRadix), FFTRadix(FFT_RADIX2))
                let windows = UnsafeMutablePointer<Float>.alloc(sample数量)
                vDSP_hamm_window(windows, vDSP_Length(sample数量), 0)
                vDSP_vmul(samples, 1, windows, 1, samples, 1, vDSP_Length(sample数量));
                var A=COMPLEX_SPLIT(realp: UnsafeMutablePointer<Float>.alloc(halfSample), imagp: UnsafeMutablePointer<Float>.alloc(halfSample))
                vDSP_ctoz(UnsafePointer<DSPComplex>(samples), 2, &A, 1, vDSP_Length(sample数量/2))
                vDSP_fft_zrip(fftSetup, &A, 1, vDSP_Length(fftRadix), FFTDirection(FFT_FORWARD))
                var normFactor = 1.0 / Float(2 * sample数量)
                vDSP_vsmul(A.realp, 1, &normFactor, A.realp, 1, vDSP_Length(halfSample))
                vDSP_vsmul(A.imagp, 1, &normFactor, A.imagp, 1, vDSP_Length(halfSample))
                A.imagp[0] = 0.0
                var fft = [Float](count:Int(sample数量), repeatedValue:0.0)
                vDSP_zvmags(&A, 1, &fft, 1, vDSP_Length(halfSample))
                var dbv = [Float](count:Int(频率样本数), repeatedValue:0.0)
                for i in 0..<频率样本数 {
                    dbv[i] = 10 * log10(fft[2+i])
                }
                最新数据=dbv
                NSNotificationCenter.defaultCenter().postNotificationName(通知名称, object: dbv)
                vDSP_destroy_fftsetup(fftSetup)
                samples.dealloc(sample数量)
                windows.dealloc(sample数量)
                A.realp.dealloc(halfSample)
                A.imagp.dealloc(halfSample)
            }
        }
    }
    
}
