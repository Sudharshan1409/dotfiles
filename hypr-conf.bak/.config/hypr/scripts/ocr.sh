#!/bin/bash
# OCR Script using grim, slurp, and tesseract

# Check dependencies
if ! command -v tesseract &> /dev/null; then
    notify-send \
        --app-name="OCR Tool" \
        --icon="dialog-error" \
        --urgency=critical \
        "❌ OCR Error" \
        "tesseract is not installed.\nPlease install 'tesseract' and language data." \
        -t 6000
    exit 1
fi

if ! command -v grim &> /dev/null; then
    notify-send \
        --app-name="OCR Tool" \
        --icon="dialog-error" \
        --urgency=critical \
        "❌ OCR Error" \
        "grim is not installed.\nPlease install 'grim' screenshot tool." \
        -t 6000
    exit 1
fi

if ! command -v slurp &> /dev/null; then
    notify-send \
        --app-name="OCR Tool" \
        --icon="dialog-error" \
        --urgency=critical \
        "❌ OCR Error" \
        "slurp is not installed.\nPlease install 'slurp' region selector." \
        -t 6000
    exit 1
fi

# Select area and capture
IMG="/tmp/ocr_capture.png"
grim -g "$(slurp)" "$IMG"

if [ $? -ne 0 ]; then
    notify-send \
        --app-name="OCR Tool" \
        --icon="dialog-cancel" \
        --urgency=low \
        "🚫 OCR Cancelled" \
        "Selection was cancelled by user." \
        -t 2000
    exit 0
fi

# OCR
TEXT=$(tesseract "$IMG" stdout 2>/dev/null)

if [ -z "$TEXT" ]; then
    notify-send \
        --app-name="OCR Tool" \
        --icon="dialog-information" \
        --urgency=low \
        "📝 No Text Detected" \
        "No text was found in the selected region." \
        -t 4000
    rm "$IMG"
    exit 1
fi

# Copy to clipboard
echo -n "$TEXT" | wl-copy
notify-send \
    --app-name="OCR Tool" \
    --icon="scanner" \
    --urgency=normal \
    "📋 OCR Complete" \
    "Text successfully extracted and copied to clipboard!" \
    -t 4000

# Cleanup
rm "$IMG"
