//
//  Player.swift
//  SwiftUIAVPlayer
//
//  Created by Jon Gary on 7/13/20.
//  Copyright © 2020 Jon Gary. All rights reserved.
//

import AVFoundation
import Combine

let timeScale = CMTimeScale(1000)
let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)

enum PlayerScrubState {
    case reset
    case scrubStarted
    case scrubEnded(TimeInterval)
}

/// AVPlayer wrapper to publish the current time and
/// support a slider for scrubbing.
final class Player: NSObject, ObservableObject {

    /// Display time that will be bound to the scrub slider.
    @Published var displayTime: TimeInterval = 0

    /// The observed time, which may not be needed by the UI.
    @Published var observedTime: TimeInterval = 0

    @Published var itemDuration: TimeInterval = 0
    fileprivate var itemDurationKVOPublisher: AnyCancellable!

    /// Publish timeControlStatus
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    fileprivate var timeControlStatusKVOPublisher: AnyCancellable!

    /// The AVPlayer
    fileprivate var avPlayer: AVPlayer

    /// Time observer.
    fileprivate var periodicTimeObserver: Any?

    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .reset:
                return
            case .scrubStarted:
                return
            case .scrubEnded(let seekTime):
                avPlayer.seek(to: CMTime(seconds: seekTime, preferredTimescale: 1000))
            }
        }
    }

    init(avPlayer: AVPlayer) {
        self.avPlayer = avPlayer
        super.init()

        self.addPeriodicTimeObserver()
        self.addTimeControlStatusObserver()
        self.addItemDurationPublisher()
    }

    deinit {
        removePeriodicTimeObserver()
        timeControlStatusKVOPublisher.cancel()
        itemDurationKVOPublisher.cancel()
    }

    func play() {
        self.avPlayer.play()
    }

    func pause() {
        self.avPlayer.pause()
    }

    fileprivate func addPeriodicTimeObserver() {
        self.periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] (time) in
            guard let self = self else { return }

            // Always update observed time.
            self.observedTime = time.seconds

            switch self.scrubState {
            case .reset:
                self.displayTime = time.seconds
            case .scrubStarted:
                // When scrubbing, the displayTime is bound to the Slider view, so
                // do not update it here.
                break
            case .scrubEnded(let seekTime):
                self.scrubState = .reset
                self.displayTime = seekTime
            }
        }
    }

    fileprivate func removePeriodicTimeObserver() {
        guard let periodicTimeObserver = self.periodicTimeObserver else {
            return
        }
        avPlayer.removeTimeObserver(periodicTimeObserver)
        self.periodicTimeObserver = nil
    }

    fileprivate func addTimeControlStatusObserver() {
        timeControlStatusKVOPublisher = avPlayer
            .publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let self = self else { return }
                self.timeControlStatus = newStatus
                }
        )
    }

    fileprivate func addItemDurationPublisher() {
        itemDurationKVOPublisher = avPlayer
            .publisher(for: \.currentItem?.duration)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let newStatus = newStatus,
                    let self = self else { return }
                self.itemDuration = newStatus.seconds
                }
        )
    }

}
