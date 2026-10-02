import AVFoundation
let a = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
guard let t = a.tracks(withMediaType: .video).first else { print("0x0 0"); exit(1) }
let r = CGRect(origin: .zero, size: t.naturalSize).applying(t.preferredTransform)
print("\(Int(abs(r.width)))x\(Int(abs(r.height))) \(CMTimeGetSeconds(a.duration)) audio=\(a.tracks(withMediaType: .audio).count)")
