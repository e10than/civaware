// usage: dump_frames <video> <outDir> <everySeconds> : writes small JPEG thumbnails for finding scene times
import AVFoundation
import AppKit
let a = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.maximumSize = CGSize(width: Double(a.count > 4 ? a[4] : "300")!, height: 1200)
gen.requestedTimeToleranceBefore = .zero; gen.requestedTimeToleranceAfter = .zero
try? FileManager.default.createDirectory(atPath: a[2], withIntermediateDirectories: true)
let step = Double(a[3]) ?? 2
let dur = CMTimeGetSeconds(asset.duration)
var t = 0.0, i = 0
while t < dur {
    if let img = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) {
        let rep = NSBitmapImageRep(cgImage: img)
        try? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])?.write(to: URL(fileURLWithPath: String(format: "%@/t%04d.jpg", a[2], Int(t))))
    }
    t += step; i += 1
}
print("frames:", i)
