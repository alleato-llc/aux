import Foundation
import Tint
import LibAVKit

public struct NowPlayingRenderer {
    public static func render(
        state: PlayerState,
        area: Rect,
        theme: PlayerTheme,
        buffer: inout Buffer
    ) {
        guard !area.isEmpty else { return }

        // Fill background
        buffer.fill(area, cell: Cell(character: " ", style: theme.statusBar))

        // Vertically center the content in the available area
        let contentY = area.y + max(0, (area.height - 3) / 2)

        guard let track = state.currentTrack else {
            let text = "  No track playing"
            buffer.write(text, x: area.x, y: contentY, style: theme.statusBar)
            // Show volume even with no track
            let volText = volumeText(state.volume)
            let volX = area.x + area.width - volText.count
            if volX > area.x + text.count {
                buffer.write(volText, x: volX, y: contentY, style: theme.statusBar)
            }
            return
        }

        let stateIcon: String
        switch state.player.state {
        case .playing: stateIcon = "▶"
        case .paused: stateIcon = "⏸"
        default: stateIcon = "⏹"
        }

        let elapsed = state.player.currentTime
        let duration = state.player.duration

        let trackInfo = " \(stateIcon) \(track.title) - \(track.artist)"
        let timeText = " \(formatTime(elapsed)) / \(formatTime(duration)) "

        // Row 1: track info
        let truncInfo = String(trackInfo.prefix(area.width))
        buffer.write(truncInfo, x: area.x, y: contentY, style: theme.statusBar.merging(Style(bold: true)))

        // Row 2: progress bar
        let barY = contentY + 1
        if barY < area.bottom && area.width > 4 {
            let barArea = Rect(x: area.x + 1, y: barY, width: area.width - 2, height: 1)
            let progress = duration > 0 ? elapsed / duration : 0
            let bar = ProgressBar(
                progress: progress,
                filledStyle: theme.statusBar.merging(theme.visualizer),
                emptyStyle: theme.statusBar.merging(Style(fg: .brightBlack)),
                showBrackets: true
            )
            bar.render(area: barArea, buffer: &buffer)
        }

        // Row 3: time + volume
        let timeY = contentY + 2
        if timeY < area.bottom {
            buffer.write(timeText, x: area.x, y: timeY, style: theme.statusBar)
            let volText = volumeText(state.volume)
            let volX = area.x + area.width - volText.count
            if volX > area.x + timeText.count {
                buffer.write(volText, x: volX, y: timeY, style: theme.statusBar)
            }
        }
    }

    private static func volumeText(_ volume: Float) -> String {
        let percent = Int(round(volume * 100))
        let filled = percent / 10
        let empty = 10 - filled
        let bar = String(repeating: "\u{2588}", count: filled) + String(repeating: "\u{2591}", count: empty)
        return String(format: "Vol %@%4d%% ", bar, percent)
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
