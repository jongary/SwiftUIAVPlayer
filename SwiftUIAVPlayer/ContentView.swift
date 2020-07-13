//
//  ContentView.swift
//  SwiftUIAVPlayer
//
//  Created by Jon Gary on 7/13/20.
//  Copyright © 2020 Jon Gary. All rights reserved.
//
import AVFoundation
import SwiftUI

/// A view that just has a play/pause button and a slider
/// to scrub through the audio.
struct ContentView: View {
    /// The player, which wraps an AVPlayer
    @ObservedObject var player: Player
    
    var body: some View {
        VStack {
            Button(action: {
                switch self.player.timeControlStatus {
                case .paused:
                    self.player.play()
                case .waitingToPlayAtSpecifiedRate:
                    self.player.pause()
                case .playing:
                    self.player.pause()
                @unknown default:
                    fatalError()
                }
            }) {
                Image(systemName: self.player.timeControlStatus == .paused ? "play" : "pause")
            }

            HStack {
                Text("Display time")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                Text(self.durationFormatter.string(from: self.player.displayTime) ?? "")
            }

            /// This is a bit of a hack, but it takes a moment for the AVPlayerItem to load
            /// the duration, so we need to avoid adding the slider until the range
            /// (0...self.player.duration) is not empty.
            if self.player.duration > 0 {
                Slider(value: self.$player.displayTime, in: (0...self.player.duration), onEditingChanged: {
                    (scrubStarted) in
                    self.player.scrubState = scrubStarted ? .scrubStarted : .scrubEnded(self.player.displayTime)
                })
            } else {
                Text("Slider will appear here when the player is ready")
                    .font(.footnote)
            }
        }
    }

    /// Return a formatter for durations.
    var durationFormatter: DateComponentsFormatter {

        let durationFormatter = DateComponentsFormatter()
        durationFormatter.allowedUnits = [.minute, .second]
        durationFormatter.unitsStyle = .positional
        durationFormatter.zeroFormattingBehavior = .pad

        return durationFormatter
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(player: Player(avPlayer: AVPlayer()))
    }
}
