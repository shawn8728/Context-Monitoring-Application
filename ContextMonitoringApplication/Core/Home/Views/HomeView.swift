//
//  ContentView.swift
//  ContextMonitoringApplication
//
//  Created by Shawn Wang on 9/6/23.
//

import SwiftUI
import UniformTypeIdentifiers

import AVFoundation
import UIKit

class SlowTask {
    func processMedia(atPath path: URL, completion: @escaping (Int64?) -> Void) {
        let asset = AVAsset(url: path)
        let assetGenerator = AVAssetImageGenerator(asset: asset)
        
        var frameList: [UIImage] = []
        
        // Get video frame rate from first track
        guard let track = asset.tracks(withMediaType: .video).first else {
            return
        }
        
        let frameRate = Int(track.nominalFrameRate)
        
        // Extract frames
        let duration = CMTimeGetSeconds(asset.duration)
        let totalFrames = Int(duration) * frameRate
        
        var i = 10
        while i < totalFrames {
            if let cgImage = try? assetGenerator.copyCGImage(at: CMTime(seconds: Double(i) / Double(frameRate), preferredTimescale: 600), actualTime: nil) {
                frameList.append(UIImage(cgImage: cgImage))
            }
            i += 5
        }
        
        // Initialize variables for calculations
        var redBucket: Int64 = 0
        var pixelCount: Int64 = 0
        var a: [Int64] = []
        
        // Get the image's width and height
        var imageWidth: Int = 0
        var imageHeight: Int = 0
        
        if let lastImage = frameList.last {
            imageWidth = Int(lastImage.size.width)
            imageHeight = Int(lastImage.size.height)
        }
        
        // Process each frame in frameList
        for image in frameList {
            redBucket = 0
            guard let cgImage = image.cgImage else { continue }
            
            // Only consider the 100x100 pixel area
            for y in imageHeight-100..<imageHeight {
                for x in imageWidth-100..<imageWidth {
                    let pixelData = cgImage.dataProvider?.data
                    let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
                    let pixelInfo: Int = ((Int(cgImage.width) * y) + x) * 4
                    
                    let r = CGFloat(data[pixelInfo])
                    let g = CGFloat(data[pixelInfo + 1])
                    let b = CGFloat(data[pixelInfo + 2])
                    
                    pixelCount += 1
                    redBucket += Int64(r + g + b)
                }
            }
            a.append(redBucket)
        }
        
        // Compute rolling average
        var b: [Int64] = []
        for i in 0..<a.count-5 {
            let temp = (a[i] + a[i+1] + a[i+2] + a[i+3] + a[i+4]) / 4
            b.append(temp)
        }
        
        // Calculate rate
        var x = b[0]
        var count = 0
        for i in 1..<b.count {
            let p = b[i]
            if (p - x) > 500 {
                count += 1
            }
            x = b[i]
        }
        
        let rate = ((CGFloat(count) / 45.0) * 60.0).rounded(.down)
        completion(Int64(rate / 2))
    }
}

struct HomeView: View {
    @State private var showFileImporter: Bool = false
    @State private var isPickerPresented: Bool = false
    
    @State private var videoURL: URL?
    @State private var csvURL: URL?
    
    @State public var respiratoryRate: Int64 = 0
    @State public var heartRate: Int64 = 0
    
    @State private var x: [Float] = []
    @State private var y: [Float] = []
    @State private var z: [Float] = []
    
    @State private var isRespiratoryRateButtonDisabled = true
    @State private var isHeartRateButtonDisabled = false
    
    var body: some View {
        NavigationView {
            VStack {
                // symptoms rating
                NavigationLink(destination: SymptomsView(heartRate: $heartRate, respiratoryRate: $respiratoryRate)) {
                    Text("Symptoms")
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom, 50)
                
                // upload signs
                Text("Selected file: \(csvURL?.lastPathComponent ?? "None")")
                
                Button(action:{
                    showFileImporter = true
                }, label: {
                    Text("Upload Signs")
                })
                .padding(.bottom, 50)
                .buttonStyle(.borderedProminent)
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [UTType.commaSeparatedText]
                ) { result in
                    switch result {
                    case .success(let url):
                        x.removeAll()
                        y.removeAll()
                        z.removeAll()
                        csvURL = url
                        handleCSV(url: url)
                        isRespiratoryRateButtonDisabled = false
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                
                // upload heart rate
                Text("Selected Video: \(videoURL?.lastPathComponent ?? "None")")
                
                Button(action:{
                    isPickerPresented = true
                }, label: {
                    Text("Upload Heart Rate")
                })
                .padding(.bottom, 50)
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $isPickerPresented, content: {
                    VideoPicker(videoURL: $videoURL)
                })
                
                // measure heart rate
                Text("Heart Rate: \(heartRate)")
                Button(action:{
                    if let unwrappedURL = videoURL {
                        handleVideo(url: unwrappedURL)
                        print("Computed heart rate: \(heartRate)")
                    } else {
                        print("videoURL is nil")
                    }
                }, label: {
                    Text("Measure Heart Rate")
                })
                .padding(.bottom, 50)
                .buttonStyle(.borderedProminent)
                .disabled(isHeartRateButtonDisabled)
                
                // measure respiratory rate
                Text("Respiratory Rate: \(respiratoryRate)")
                Button(action:{
                    respiratoryRate = callRespiratoryCalculator(threshold: 0.0589)
                    print("Computed respiratory rate: \(respiratoryRate)")
                }, label: {
                    Text("Measure Respiratory Rate")
                })
                .buttonStyle(.borderedProminent)
                .disabled(isRespiratoryRateButtonDisabled)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: HistoryView()) {
                        Text("History")
                    }
                }
            }
        }
    }
    
    func handleVideo(url: URL) {
        let slowTask = SlowTask()
        
        slowTask.processMedia(atPath: url) { rate in
            heartRate = rate ?? 0
        }
    }
    
    func handleCSV(url: URL) {
        // Handle the CSV content
        do {
            let dataContents = try String(contentsOf: url)
            let lines = dataContents.split(separator: "\n").map { String($0) }
            
            var currentAxis = -1
            
            for line in lines {
                if let value = Float(line) {
                    if value == 0.0 {
                        currentAxis += 1
                    }
                    
                    switch currentAxis {
                    case 0:
                        x.append(value)
                    case 1:
                        y.append(value)
                    case 2:
                        z.append(value)
                    default:
                        break
                    }
                }
            }
        } catch {
            print("Error reading CSV: \(error)")
        }
    }
    
    func callRespiratoryCalculator(threshold: Float) -> Int64 {
        var previousValue: Float = 10.0
        var currentValue: Float = 0.0
        var k: Int = 0
        
        for i in 11...450 {
            currentValue = sqrtf(
                powf(z[i], 2) +
                powf(x[i], 2) +
                powf(y[i], 2)
            )
            
            if abs(previousValue - currentValue) > threshold {
                k += 1
            }
            previousValue = currentValue
        }
        
        let ret = Float(k) / 45.0
        return Int64(ret * 30)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
