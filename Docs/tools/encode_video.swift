// Encodes numbered JPEG frames + a WAV into an H.264/AAC MP4 using AVFoundation (no extra installs).
// usage: encode_video <framesDir> <fps> <audio.wav> <out.mp4>
import AVFoundation
import AppKit

let args = CommandLine.arguments
guard args.count == 5, let fps = Int32(args[2]) else { print("usage: encode_video <framesDir> <fps> <audio.wav> <out.mp4>"); exit(1) }
let dir = args[1], audioPath = args[3], outPath = args[4]
let tmpVideo = NSTemporaryDirectory() + "civaware_video_only.mp4"
try? FileManager.default.removeItem(atPath: tmpVideo)
try? FileManager.default.removeItem(atPath: outPath)

let names = try FileManager.default.contentsOfDirectory(atPath: dir).filter { $0.hasSuffix(".jpg") }.sorted()
func loadImage(_ n: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: dir + "/" + n) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}
guard let first = loadImage(names[0]) else { print("cannot read frames"); exit(1) }
let width = first.width, height = first.height

let writer = try AVAssetWriter(outputURL: URL(fileURLWithPath: tmpVideo), fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 6_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

for (i, name) in names.enumerated() {
    guard let img = loadImage(name) else { continue }
    while !input.isReadyForMoreMediaData { usleep(2000) }
    var pb: CVPixelBuffer?
    CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &pb)
    guard let buffer = pb else { continue }
    CVPixelBufferLockBaseAddress(buffer, [])
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8,
                        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    ctx?.draw(img, in: CGRect(x: 0, y: 0, width: width, height: height))
    CVPixelBufferUnlockBaseAddress(buffer, [])
    adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
}
input.markAsFinished()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }
sem.wait()
if writer.status != .completed { print("video write failed: \(String(describing: writer.error))"); exit(1) }

// Mux with audio
let comp = AVMutableComposition()
let vAsset = AVURLAsset(url: URL(fileURLWithPath: tmpVideo))
let aAsset = AVURLAsset(url: URL(fileURLWithPath: audioPath))
let dur = vAsset.duration
if let vt = vAsset.tracks(withMediaType: .video).first, let cv = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
    try cv.insertTimeRange(CMTimeRange(start: .zero, duration: dur), of: vt, at: .zero)
}
if let at = aAsset.tracks(withMediaType: .audio).first, let ca = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
    try ca.insertTimeRange(CMTimeRange(start: .zero, duration: min(dur, aAsset.duration)), of: at, at: .zero)
}
guard let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality) else { print("no export session"); exit(1) }
export.outputURL = URL(fileURLWithPath: outPath)
export.outputFileType = .mp4
export.shouldOptimizeForNetworkUse = true
let sem2 = DispatchSemaphore(value: 0)
export.exportAsynchronously { sem2.signal() }
sem2.wait()
if export.status == .completed { print("wrote \(outPath)") } else { print("export failed: \(String(describing: export.error))"); exit(1) }
