#!/bin/bash

# Screen recorder using wf-recorder + slurp.
# Toggle: if a recording is in progress the bind stops it; otherwise a rofi
# menu picks the recording mode. Output: ~/Videos/Recordings/screen-<ts>.mp4
# Stopped recording path is copied to the clipboard.
#
# Audio note: --audio captures from the default PulseAudio source. To record
# system audio instead of mic, set your default source to the sink monitor
# (e.g. pactl set-default-source <sink-name>.monitor) before recording.

ROFI_THEME="$HOME/.config/rofi/audio-switcher.rasi"
RECORDINGS_DIR="$HOME/Videos/Recordings"

for cmd in wf-recorder slurp jq notify-send rofi wl-copy; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        notify-send "Screen Recorder" "Missing dependency: $cmd" -i dialog-error -t 5000
        exit 1
    fi
done

mkdir -p "$RECORDINGS_DIR"

is_recording() {
    pgrep -x wf-recorder >/dev/null
}

stop_recording() {
    pkill -INT -x wf-recorder
    # Give wf-recorder time to finalize the file
    for _ in $(seq 1 20); do
        is_recording || break
        sleep 0.1
    done

    local latest
    latest=$(ls -t "$RECORDINGS_DIR"/*.mp4 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        echo -n "$latest" | wl-copy
        notify-send "Screen Recorder" \
            "🎬 Recording saved\n$(basename "$latest")\nPath copied to clipboard." \
            -i media-playback-stop -t 5000
    else
        notify-send "Screen Recorder" "Recording stopped" -i media-playback-stop -t 3000
    fi
}

start_recording() {
    local mode="$1"
    local with_audio="$2"
    local output="$RECORDINGS_DIR/screen-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
    local audio_flag=()
    [ "$with_audio" = "yes" ] && audio_flag=(--audio)

    case "$mode" in
        region)
            local geom
            geom=$(slurp 2>/dev/null)
            if [ -z "$geom" ]; then
                notify-send "Screen Recorder" "Region selection cancelled" -i dialog-cancel -t 2000
                exit 0
            fi
            wf-recorder -g "$geom" "${audio_flag[@]}" -f "$output" &
            ;;
        window)
            local geom
            geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            wf-recorder -g "$geom" "${audio_flag[@]}" -f "$output" &
            ;;
        screen)
            local monitor
            monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused == true) | .name')
            wf-recorder -o "$monitor" "${audio_flag[@]}" -f "$output" &
            ;;
    esac

    disown

    local audio_msg=""
    [ "$with_audio" = "yes" ] && audio_msg=" (with audio)"
    notify-send "Screen Recorder" \
        "🎬 Recording started${audio_msg}\nSuper+Alt+R to stop." \
        -i media-record -t 3000
}

# Toggle: if already recording, stop and exit.
if is_recording; then
    stop_recording
    exit 0
fi

MENU="📐 Region (silent)
📐 Region with audio
🪟 Active window (silent)
🪟 Active window with audio
🖥️  Full screen (silent)
🖥️  Full screen with audio"

SELECTED=$(echo -e "$MENU" | rofi -dmenu \
    -p "Record" \
    -theme "$ROFI_THEME" \
    -mesg "Select recording mode | Super+Alt+R again to stop" \
    -i)

case "$SELECTED" in
    "📐 Region (silent)")         start_recording region no ;;
    "📐 Region with audio")       start_recording region yes ;;
    "🪟 Active window (silent)")  start_recording window no ;;
    "🪟 Active window with audio") start_recording window yes ;;
    "🖥️  Full screen (silent)")   start_recording screen no ;;
    "🖥️  Full screen with audio") start_recording screen yes ;;
    *) exit 0 ;;
esac
