import { Controller } from "@hotwired/stimulus"
import WaveSurfer from "wavesurfer.js"

// Renders a wavesurfer.js waveform for a single sound and wires up the
// play/pause button, the current-time / duration readout, and the playback
// speed selector. One controller instance drives one player, so the same
// markup works for the feed (many players) and the show page (one player).
//
// The waveform is only created once the element scrolls into view, so a long
// feed doesn't fetch and decode every audio file up front.
//
// When the server supplies precomputed peaks and duration, the waveform is
// drawn from those and the audio file isn't downloaded until the listener hits
// Play. Without them (e.g. a sound whose GenerateWaveformJob hasn't run yet),
// wavesurfer falls back to fetching and decoding the whole file to draw it.
export default class extends Controller {
  static targets = ["waveform", "playPause", "time", "speed"]
  static values = { url: String, playUrl: String, peaks: Array, duration: Number }

  connect() {
    this.observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) {
        this.initWaveSurfer()
        this.observer.disconnect()
      }
    })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    this.wavesurfer?.destroy()
    this.wavesurfer = null
  }

  initWaveSurfer() {
    if (this.wavesurfer) return

    const options = {
      container: this.waveformTarget,
      url: this.urlValue,
      height: 64,
      waveColor: "#c7d2fe",
      progressColor: "#4f46e5",
      cursorColor: "#4f46e5",
      barWidth: 2,
      barGap: 1,
      barRadius: 2
    }

    // Passing both peaks and duration tells wavesurfer to render from them and
    // defer loading the audio until playback, so the feed draws without
    // downloading every file. wavesurfer expects one array of samples per
    // channel; our peaks are mono.
    if (this.hasPeaksValue && this.peaksValue.length && this.hasDurationValue) {
      options.peaks = [this.peaksValue]
      options.duration = this.durationValue
    }

    this.wavesurfer = WaveSurfer.create(options)

    this.wavesurfer.on("ready", () => this.updateTime())
    this.wavesurfer.on("timeupdate", () => this.updateTime())
    this.wavesurfer.on("play", () => this.setPlaying(true))
    this.wavesurfer.on("pause", () => this.setPlaying(false))
    this.wavesurfer.on("finish", () => {
      this.setPlaying(false)
      this.recordPlay()
    })
  }

  // The "finish" event only fires when playback reaches the end of the track, so
  // this counts full plays and not partial listens. Fire-and-forget: a failed
  // request just means an uncounted play, which shouldn't disrupt the listener.
  recordPlay() {
    if (!this.hasPlayUrlValue) return

    const token = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.playUrlValue, {
      method: "POST",
      headers: token ? { "X-CSRF-Token": token } : {}
    }).catch(() => {})
  }

  togglePlay() {
    this.wavesurfer?.playPause()
  }

  changeSpeed() {
    this.wavesurfer?.setPlaybackRate(parseFloat(this.speedTarget.value), true)
  }

  setPlaying(playing) {
    if (this.hasPlayPauseTarget) this.playPauseTarget.textContent = playing ? "Pause" : "Play"
  }

  updateTime() {
    if (!this.hasTimeTarget || !this.wavesurfer) return
    const current = this.formatTime(this.wavesurfer.getCurrentTime())
    const duration = this.formatTime(this.wavesurfer.getDuration())
    this.timeTarget.textContent = `${current} / ${duration}`
  }

  formatTime(seconds) {
    const total = Math.floor(seconds || 0)
    const minutes = Math.floor(total / 60)
    const secs = (total % 60).toString().padStart(2, "0")
    return `${minutes}:${secs}`
  }
}
