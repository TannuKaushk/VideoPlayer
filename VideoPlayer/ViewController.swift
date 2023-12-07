//
//  ViewController.swift
//  VideoPlayer
//
//  Created by Tannu Kaushik on 20/07/23.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var expandView: UIImageView!{
        didSet {
            self.expandView.isUserInteractionEnabled = true
            self.expandView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapFullScreen)))
        }
    }
    
    @IBOutlet weak var stackViewButton: UIStackView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var sliderLabel: UISlider! {
        didSet {
            self.sliderLabel.addTarget(self, action: #selector(onTapSlider), for: .valueChanged)
        }
    }
    @IBOutlet weak var lbTotalTime: UILabel!
    @IBOutlet weak var lbCurrentTime: UILabel!
    @IBOutlet weak var img10SecFow: UIImageView!{
        didSet {
            self.img10SecFow.isUserInteractionEnabled = true
            self.img10SecFow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap10SecFor)))
        }
    }
    @IBOutlet weak var img10SecBack: UIImageView!{
        didSet {
            self.img10SecBack.isUserInteractionEnabled = true
            self.img10SecBack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap10SecBack)))
        }
    }
    @IBOutlet weak var playButton: UIImageView! {
        didSet {
            self.playButton.isUserInteractionEnabled = true
            self.playButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlayPauseVideoOnTap)))
        }
    }
    @IBOutlet weak var heightVideoPlayer: NSLayoutConstraint!
    @IBOutlet weak var videoPlayer: UIView!
    
  //  let videoURL = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
     let videoURL = "https://action-ott-live.s3.ap-south-1.amazonaws.com/Raees/Raees.mp4"
    
    private var player : AVPlayer? = nil
    private var playerLayer : AVPlayerLayer? = nil
    private var timeObserver: Any? = nil
    private var isThumbSeek: Bool = false
    private var thubmnailImage : UIImage? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setVideoPlayer()
    }
    
    /// Video Player Setup......
    private func setVideoPlayer() {
        guard let url = URL(string: videoURL) else { return }
        
        if self.player == nil {
            self.player = AVPlayer(url: url)
            self.playerLayer = AVPlayerLayer(player: self.player)
            self.playerLayer?.videoGravity = .resizeAspectFill
            self.playerLayer?.frame = self.videoPlayer.bounds
            self.playerLayer?.addSublayer(innerView.layer)
            player?.currentItem?.preferredPeakBitRate = -1
            if let playerLayer = self.playerLayer {
                self.videoPlayer.layer.addSublayer(playerLayer)
            }
            self.player?.play()
        }
        player?.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        setObserverToPlayer()
    }
    
    /// 10 sec button Action for backward direction
    @objc func onTap10SecBack() {
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10Sec = CMTimeGetSeconds(currentTime).advanced(by: -10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10Sec), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
        })
    }
    
    /// 10 sec button Action for forward direction
    @objc func onTap10SecFor() {
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10Sec = CMTimeGetSeconds(currentTime).advanced(by: 10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10Sec), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
        })
    }
    
    /// Button Action for switch to full Screen
    @objc func onTapFullScreen() {
        if #available(iOS 16.0, *) {
            guard let windowSceen = self.view.window?.windowScene else { return }
            if windowSceen.interfaceOrientation == .portrait {
                windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                    print(error.localizedDescription)
                }
            } else {
                windowSceen.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                    print(error.localizedDescription)
                }
            }
        } else {
            if UIDevice.current.orientation == .portrait {
                let orientation = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(orientation, forKey: "orientation")
            } else {
                let orientation = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(orientation, forKey: "orientation")
            }
        }
    }
    /// Play and pause functionality
    @objc func PlayPauseVideoOnTap() {
        if self.player?.timeControlStatus == .playing {
            self.playButton.image = UIImage(systemName: "pause.circle.fill")
            self.player?.pause()
        } else {
            self.playButton.image = UIImage(systemName: "")
            self.player?.play()
        }
    }
    
    @objc func onTapSlider() {
        self.isThumbSeek = true
        if self.sliderLabel.isTracking == true {
        } else {
            guard let duration = self.player?.currentItem?.duration else {
                return
            }
            
            let value = Int64(self.sliderLabel.value*1000)
            let seekTime = CMTime(value: CMTimeValue(value), timescale: 1000)
            self.player?.seek(to: seekTime, completionHandler: { completed in
                if completed {
                    self.isThumbSeek = false
                }
            })
        }
    }
    
    
    private var windowInterfaces: UIInterfaceOrientation? {
        return self.view.window?.windowScene?.interfaceOrientation
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard let windowInterfaces = windowInterfaces else {
            return
        }
        if windowInterfaces.isPortrait == true {
            self.heightVideoPlayer.constant = 250
        } else {
            
            self.heightVideoPlayer.constant = self.view.layer.bounds.width
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playerLayer?.frame = self.videoPlayer.bounds
        }
    }
    /// method for observe player timer to update timer on screen
    private func setObserverToPlayer() {
        let interval = CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsed in
            self.updatePlayerTime()
        })
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "duration", let duration = player?.currentItem?.duration.seconds, duration > 0.0 {
            guard (self.player?.currentItem!.duration)! >= .zero, !(self.player?.currentItem?.duration.seconds.isNaN)! else {
                return
            }
            guard let duration = self.player?.currentItem?.duration else { return }
            
            
            self.lbTotalTime.text = getTimeString(from: duration)
        }
    }
    func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds/3600)
        let min = Int(totalSeconds/60) % 60
        let second = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,min,second])
        } else {
            return String(format: "%i:%02i", arguments: [min,second])
        }
    }
    private func updatePlayerTime() {
        guard let currentTime = self.player?.currentItem?.currentTime() else { return }
        guard let duration = self.player?.currentItem?.duration else { return }
        guard (self.player?.currentItem!.duration)! >= .zero, !(self.player?.currentItem?.duration.seconds.isNaN)! else {
            return
        }
        let currentTimeInSec = CMTimeGetSeconds(currentTime)
        let durationTimeInSec = CMTimeGetSeconds(duration)
        self.sliderLabel.maximumValue = Float(duration.seconds)
        self.sliderLabel.minimumValue = 0.000000
        if isThumbSeek == false {
            self.sliderLabel.value = Float(currentTime.seconds)
        }
        self.lbCurrentTime.text = self.getTimeString(from: currentTime)
    }
}

