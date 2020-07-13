#  Using SwiftUI's Slider view with AVPlayer

I recently decided to learn Swift UI by porting my application
Playertronic from UIKit. I wrestled a bit with how to implement a slider
to scrub through the audio file. My UIKit implementation used state
stored in the view controller layer to select between the current
playback time and the user-selected time while the slider was being
interacted with, while displaying the time in the same view on screen.
Some others I've seen online trying to do the same were struggling as well.

The approach I came up with uses a `ObservableObject` to wrap an
`AVPlayer`. This class publishes a property called `displayTime`, which
represents the playback time, unless the Slider is active. The Slider
is bound to the player.displayTime property, and the slider's action
sets a scrubControl property on the player so it can avoid updating
displayTime during the scrub (when the value is set by the binding).

### Slider

In `ContentView`
```
Slider(value: self.$player.displayTime,
          in: (0...self.player.itemDuration),
          onEditingChanged: { (scrubStarted) in
    if scrubStarted {
        self.player.scrubState = .scrubStarted
    } else {
        self.player.scrubState = .scrubEnded(self.player.displayTime)
    }
})

```

### scrubControl

In `Player`

```
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

```

### Time observation
In `Player`

```

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
```

The attached project illustrates this approach. I really like SwiftUI
and Combine look forward to rewiring my brain to use them effectively.

PS: The embedded audio file was my first GarageBand creation from 15 years ago!
