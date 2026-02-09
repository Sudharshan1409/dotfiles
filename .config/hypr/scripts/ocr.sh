#!/bin/bash
# OCR Script using grim, slurp, and tesseract

# Check dependencies
if ! command -v tesseract &> /dev/null; then
    notify-send "OCR Error" "tesseract is not installed. Please install 'tesseract' (and data)." -u critical
    exit 1
fi

if ! command -v grim &> /dev/null; then
    notify-send "OCR Error" "grim is not installed." -u critical
    exit 1
fi

if ! command -v slurp &> /dev/null; then
    notify-send "OCR Error" "slurp is not installed." -u critical
    exit 1
fi

# Select area and capture
IMG="/tmp/ocr_capture.png"
grim -g "$(slurp)" "$IMG"

if [ $? -ne 0 ]; then
    notify-send "OCR" "Selection cancelled."
    exit 0
fi

# OCR
TEXT=$(tesseract "$IMG" stdout 2>/dev/null)

if [ -z "$TEXT" ]; then
    notify-send "OCR" "No text detected." -u low
    rm "$IMG"
    exit 1
fi

# Copy to clipboard
echo -n "$TEXT" | wl-copy
notify-send "OCR" "Text copied to clipboard!" -i scanner

# Cleanup
rm "$IMG"
