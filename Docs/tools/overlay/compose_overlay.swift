// Composes the final video: cuts segments from a raw screen recording, places them in the phone frame,
// animates captions, adds intro/outro cards and a soft music bed. Pure AVFoundation + Core Animation.
// usage: compose_overlay <raw_recording.mov> <assetsDir> <out.mp4>
import AVFoundation
import AppKit
import QuartzCore

struct Layer: Codable { let png: String; let x, y, w, h, start, end, fade: Double }
struct Seg: Codable { let start, end, rate: Double }
struct Manifest: Codable {
    let width, height: Double
    let hole: [Double]
    let pad_start, pad_end, video_out: Double
    let segments: [Seg]
    let layers: [Layer]
}

let args = CommandLine.arguments
guard args.count == 4 else { print("usage: compose_overlay <raw.mov> <assetsDir> <out.mp4>"); exit(1) }
let rawPath = args[1], dir = args[2], outPath = args[3]
let m = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: URL(fileURLWithPath: dir + "/manifest.json")))
let W = m.width, H = m.height
func T(_ s: Double) -> CMTime { CMTime(seconds: s, preferredTimescale: 600) }

let src = AVURLAsset(url: URL(fileURLWithPath: rawPath))
guard let srcV = src.tracks(withMediaType: .video).first else { print("no video track"); exit(1) }
let comp = AVMutableComposition()
let vTrack = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
var aTrack: AVMutableCompositionTrack? = nil
let srcA = src.tracks(withMediaType: .audio).first
if srcA != nil { aTrack = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) }

var cursor = m.pad_start
for s in m.segments {
    let range = CMTimeRange(start: T(s.start), duration: T(s.end - s.start))
    let outDur = (s.end - s.start) / s.rate
    try vTrack.insertTimeRange(range, of: srcV, at: T(cursor))
    if let a = srcA, let at = aTrack { try at.insertTimeRange(range, of: a, at: T(cursor)) }
    if s.rate != 1 {
        let placed = CMTimeRange(start: T(cursor), duration: range.duration)
        vTrack.scaleTimeRange(placed, toDuration: T(outDur)); aTrack?.scaleTimeRange(placed, toDuration: T(outDur))
    }
    cursor += outDur
}
let total = m.pad_start + m.video_out + m.pad_end

// Pre-mixed audio (quiet music + sound effects), already total-length with fades baked in
let bed = AVURLAsset(url: URL(fileURLWithPath: dir + "/bed.wav"))
let music = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
try music.insertTimeRange(CMTimeRange(start: .zero, duration: T(total)), of: bed.tracks(withMediaType: .audio)[0], at: .zero)

// Video composition: scale the footage into the phone "screen" hole
let pt = srcV.preferredTransform
let r = CGRect(origin: .zero, size: srcV.naturalSize).applying(pt)
let hole = m.hole   // x, y(top), w, h
let tf = pt.concatenating(CGAffineTransform(translationX: -r.minX, y: -r.minY))
    .concatenating(CGAffineTransform(scaleX: hole[2] / r.width, y: hole[3] / r.height))
    .concatenating(CGAffineTransform(translationX: hole[0], y: hole[1]))
let li = AVMutableVideoCompositionLayerInstruction(assetTrack: vTrack)
li.setTransform(tf, at: .zero)
let inst = AVMutableVideoCompositionInstruction()
inst.timeRange = CMTimeRange(start: .zero, duration: comp.duration)
inst.layerInstructions = [li]
let vc = AVMutableVideoComposition()
vc.renderSize = CGSize(width: W, height: H)
vc.frameDuration = CMTime(value: 1, timescale: 30)
vc.instructions = [inst]

// Core Animation overlays (origin bottom-left)
func image(_ name: String) -> CGImage? {
    guard let s = CGImageSourceCreateWithURL(URL(fileURLWithPath: dir + "/" + name) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(s, 0, nil)
}
let parent = CALayer(); parent.frame = CGRect(x: 0, y: 0, width: W, height: H)
let videoLayer = CALayer(); videoLayer.frame = parent.frame
parent.addSublayer(videoLayer)
let frameLayer = CALayer(); frameLayer.frame = parent.frame; frameLayer.contents = image("frame.png")
parent.addSublayer(frameLayer)

func fadeAnim(start: Double, end: Double, fade: Double) -> CAKeyframeAnimation {
    let d = end - start
    let a = CAKeyframeAnimation(keyPath: "opacity")
    a.values = [0, 1, 1, 0]; a.keyTimes = [0, NSNumber(value: fade / d), NSNumber(value: 1 - fade / d), 1]
    a.beginTime = AVCoreAnimationBeginTimeAtZero + start; a.duration = d
    a.isRemovedOnCompletion = false; a.fillMode = .removed
    return a
}
for l in m.layers {
    let layer = CALayer()
    layer.contents = image(l.png)
    layer.frame = CGRect(x: l.x, y: H - l.y - l.h, width: l.w, height: l.h)
    layer.opacity = 0
    layer.add(fadeAnim(start: l.start, end: l.end, fade: l.fade), forKey: "fade")
    let rise = CABasicAnimation(keyPath: "transform.translation.y")
    rise.fromValue = -16; rise.toValue = 0; rise.duration = 0.5
    rise.beginTime = AVCoreAnimationBeginTimeAtZero + l.start; rise.isRemovedOnCompletion = false; rise.fillMode = .backwards
    layer.add(rise, forKey: "rise")
    parent.addSublayer(layer)
}
// intro card fades out at the end of the start pad; outro card fades in for the end pad
let intro = CALayer(); intro.frame = parent.frame; intro.contents = image("intro.png"); intro.opacity = 0
let ia = CAKeyframeAnimation(keyPath: "opacity")
ia.values = [1, 1, 0]; ia.keyTimes = [0, NSNumber(value: (m.pad_start - 0.7) / m.pad_start), 1]
ia.beginTime = AVCoreAnimationBeginTimeAtZero; ia.duration = m.pad_start; ia.isRemovedOnCompletion = false; ia.fillMode = .both
intro.add(ia, forKey: "o"); parent.addSublayer(intro)
let outro = CALayer(); outro.frame = parent.frame; outro.contents = image("outro.png"); outro.opacity = 0
let oStart = total - m.pad_end - 0.6
let oa = CAKeyframeAnimation(keyPath: "opacity")
oa.values = [0, 1, 1]; oa.keyTimes = [0, NSNumber(value: 0.6 / (m.pad_end + 0.6)), 1]
oa.beginTime = AVCoreAnimationBeginTimeAtZero + oStart; oa.duration = m.pad_end + 0.6; oa.isRemovedOnCompletion = false; oa.fillMode = .forwards
outro.add(oa, forKey: "o"); parent.addSublayer(outro)
vc.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parent)

// Audio mix: quiet music bed with a fade-out
let mix = AVMutableAudioMix()
let mp = AVMutableAudioMixInputParameters(track: music)
mp.setVolume(1.0, at: .zero)
mix.inputParameters = [mp]
if let at = aTrack { let ap = AVMutableAudioMixInputParameters(track: at); ap.setVolume(1.0, at: .zero); mix.inputParameters.append(ap) }

try? FileManager.default.removeItem(atPath: outPath)
guard let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality) else { print("no export session"); exit(1) }
export.videoComposition = vc; export.audioMix = mix
export.outputURL = URL(fileURLWithPath: outPath); export.outputFileType = .mp4; export.shouldOptimizeForNetworkUse = true
let sem = DispatchSemaphore(value: 0)
export.exportAsynchronously { sem.signal() }
while sem.wait(timeout: .now() + 5) == .timedOut { print(String(format: "exporting %.0f%%", export.progress * 100)) }
if export.status == .completed { print("wrote \(outPath)  (\(Int(total)) s)") } else { print("export failed: \(String(describing: export.error))"); exit(1) }
