#!/usr/bin/env python3
"""
generate_real_assets.py
Generates Retina-quality assets for Ymac Player using the real macOS screenshot.
Eliminates all stretched / distorted synthetic mockups.
"""

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SRC_SCREENSHOT = "/Users/valentynbazavluk/.gemini/antigravity/brain/48e71c82-2727-4164-9757-723394e1df40/.user_uploaded/media_1790099780918.png"
APP_ICON_PATH = "/Users/valentynbazavluk/Documents/YmacPlayer/YmacPlayer/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
OUTPUT_DIR = "/Users/valentynbazavluk/Documents/YmacPlayer/docs/assets"

FONT_PATH_SF = "/System/Library/Fonts/SFNS.ttf"
FONT_PATH_HELV = "/System/Library/Fonts/HelveticaNeue.ttc"

def get_font(size, bold=False):
    try:
        return ImageFont.truetype(FONT_PATH_SF, size)
    except Exception:
        try:
            return ImageFont.truetype(FONT_PATH_HELV, size, index=1 if bold else 0)
        except Exception:
            return ImageFont.load_default()

def mask_rounded(img, radius):
    scale = 4
    mask = Image.new('L', (img.width * scale, img.height * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (img.width * scale - 1, img.height * scale - 1)], radius=radius * scale, fill=255)
    mask = mask.resize((img.width, img.height), Image.Resampling.LANCZOS)
    res = img.copy()
    res.putalpha(mask)
    return res

def cut_popover(src):
    """
    Cuts the popover window with its exact top arrow notch and rounded body.
    """
    w, h = 300, 398
    mask = Image.new('L', (w * 4, h * 4), 0)
    draw = ImageDraw.Draw(mask)

    body_top = 9 * 4
    radius = 16 * 4
    draw.rounded_rectangle([(0, body_top), (w * 4 - 1, h * 4 - 1)], radius=radius, fill=255)

    notch_tip = (148 * 4, 0)
    notch_left = (136 * 4, body_top + 2)
    notch_right = (160 * 4, body_top + 2)
    draw.polygon([notch_tip, notch_left, notch_right], fill=255)

    mask = mask.resize((w, h), Image.Resampling.LANCZOS)
    pop = src.crop((43, 27, 343, 425))
    pop.putalpha(mask)
    return pop

def create_drop_shadow(w, h, radius, blur_radius, offset_y=16, opacity=140):
    pad = blur_radius * 2
    sw, sh = w + pad * 2, h + pad * 2 + offset_y
    shadow = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle([(pad, pad + offset_y), (pad + w, pad + h + offset_y)], radius=radius, fill=(0, 0, 0, opacity))
    return shadow.filter(ImageFilter.GaussianBlur(blur_radius)), pad, pad + offset_y

def paste_with_shadow(canvas, img, x, y, radius=24, blur=24, offset_y=14, opacity=150):
    shadow, pad_x, pad_y = create_drop_shadow(img.width, img.height, radius, blur_radius=blur, offset_y=offset_y, opacity=opacity)
    canvas.alpha_composite(shadow, (x - pad_x, y - (pad_y - offset_y)))
    canvas.alpha_composite(img, (x, y))

def build_desktop_widgets_asset(src):
    """
    Builds docs/assets/desktop_widgets.png (1640 x 880)
    Shows real Medium and Small widgets side by side with true macOS WidgetKit proportions.
    """
    W, H = 1640, 880
    canvas = Image.new('RGBA', (W, H), (24, 20, 42, 255))
    draw = ImageDraw.Draw(canvas)

    for y in range(H):
        factor = y / H
        r = int(24 + 18 * factor)
        g = int(20 + 16 * factor)
        b = int(42 + 32 * factor)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

    crop_med = src.crop((489, 67, 834, 230))
    crop_small = src.crop((670, 247, 834, 411))

    med_masked = mask_rounded(crop_med, radius=22)
    small_masked = mask_rounded(crop_small, radius=22)

    med_2x = med_masked.resize((med_masked.width * 2, med_masked.height * 2), Image.Resampling.LANCZOS)
    small_2x = small_masked.resize((small_masked.width * 2, small_masked.height * 2), Image.Resampling.LANCZOS)

    font_title = get_font(34, bold=True)
    font_sub = get_font(20, bold=False)
    font_badge = get_font(18, bold=True)

    title = "Interactive Desktop Widgets"
    sub = "macOS 26+ Native WidgetKit • Real-time Album Artwork, Scrubber & Controls"
    draw.text((W // 2, 70), title, fill=(255, 255, 255, 240), font=font_title, anchor="mm")
    draw.text((W // 2, 115), sub, fill=(180, 175, 215, 210), font=font_sub, anchor="mm")

    gap = 100
    total_w = med_2x.width + gap + small_2x.width
    start_x = (W - total_w) // 2
    widgets_y = 220

    paste_with_shadow(canvas, med_2x, start_x, widgets_y, radius=44, blur=30, offset_y=18, opacity=170)

    small_y = widgets_y + (med_2x.height - small_2x.height) // 2
    paste_with_shadow(canvas, small_2x, start_x + med_2x.width + gap, small_y, radius=44, blur=30, offset_y=18, opacity=170)

    def draw_badge(x, y, text, w):
        badge_h = 38
        draw.rounded_rectangle([(x, y), (x + w, y + badge_h)], radius=19, fill=(40, 35, 65, 220), outline=(90, 80, 135, 180), width=1)
        draw.text((x + w // 2, y + badge_h // 2), text, fill=(230, 225, 255, 240), font=font_badge, anchor="mm")

    med_badge_w = 260
    draw_badge(start_x + (med_2x.width - med_badge_w) // 2, widgets_y + med_2x.height + 45, "Medium (342 × 160)", med_badge_w)

    small_badge_w = 220
    draw_badge(start_x + med_2x.width + gap + (small_2x.width - small_badge_w) // 2, widgets_y + med_2x.height + 45, "Small (160 × 160)", small_badge_w)

    draw.rectangle([(0, 0), (W - 1, H - 1)], outline=(65, 55, 100, 120), width=2)
    return canvas

def build_menu_bar_popover_asset(src):
    """
    Builds docs/assets/menu_bar_popover.png (1160 x 1000)
    Shows real Popover attached to clean macOS menu bar with real ♪ status icon.
    """
    W, H = 1160, 1000
    canvas = Image.new('RGBA', (W, H), (22, 18, 38, 255))
    draw = ImageDraw.Draw(canvas)

    for y in range(H):
        factor = y / H
        r = int(24 + 18 * factor)
        g = int(20 + 16 * factor)
        b = int(42 + 32 * factor)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

    top_bar_h = 52 # 26 * 2

    # Popover cutout and 2x scale
    pop_raw = cut_popover(src)
    pop_2x = pop_raw.resize((pop_raw.width * 2, pop_raw.height * 2), Image.Resampling.LANCZOS) # 600 x 796

    # Real menu bar strip from screenshot (contains the real ♪, ✦, ☷, 17°C icons)
    mb_strip = src.crop((43, 0, 342, 26))
    mb_strip_2x = mb_strip.resize((mb_strip.width * 2, mb_strip.height * 2), Image.Resampling.LANCZOS)

    # Popover position
    pop_x = (W - pop_2x.width) // 2 # 280
    pop_y = top_bar_h # 52

    # Menu bar top strip background
    draw.rectangle([(0, 0), (W, top_bar_h)], fill=(32, 28, 52, 245))
    draw.line([(0, top_bar_h), (W, top_bar_h)], fill=(65, 55, 95, 180), width=1)

    # Paste real menu bar strip centered right above popover notch
    canvas.alpha_composite(mb_strip_2x, (pop_x, 0))

    # Left side menu text
    font_menu = get_font(20, bold=False)
    font_menu_bold = get_font(20, bold=True)
    draw.text((36, top_bar_h // 2), "", fill=(255, 255, 255, 240), font=font_menu_bold, anchor="lm")
    draw.text((70, top_bar_h // 2), "Ymac Player", fill=(255, 255, 255, 240), font=font_menu_bold, anchor="lm")
    draw.text((200, top_bar_h // 2), "Controls", fill=(195, 190, 220, 200), font=font_menu, anchor="lm")
    draw.text((285, top_bar_h // 2), "Window", fill=(195, 190, 220, 200), font=font_menu, anchor="lm")

    # Paste popover with drop shadow
    paste_with_shadow(canvas, pop_2x, pop_x, pop_y, radius=32, blur=34, offset_y=18, opacity=190)

    # Outer border
    draw.rectangle([(0, 0), (W - 1, H - 1)], outline=(65, 55, 100, 120), width=2)
    return canvas

def build_hero_banner_asset(src):
    """
    Builds docs/assets/hero_banner.png (2200 x 880)
    Banner with Logo, Title, Features on left; REAL Popover and REAL Widgets on right.
    """
    W, H = 2200, 880
    canvas = Image.new('RGBA', (W, H), (18, 14, 30, 255))
    draw = ImageDraw.Draw(canvas)

    for y in range(H):
        factor = y / H
        r = int(18 + 14 * factor)
        g = int(14 + 12 * factor)
        b = int(30 + 26 * factor)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

    # Left Column: Branding
    if os.path.exists(APP_ICON_PATH):
        raw_icon = Image.open(APP_ICON_PATH).convert('RGBA')
        icon_size = 140
        icon_resized = raw_icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        icon_masked = mask_rounded(icon_resized, radius=32)
        paste_with_shadow(canvas, icon_masked, 120, 110, radius=32, blur=24, offset_y=12, opacity=160)
        draw.rounded_rectangle([(120, 110), (120 + icon_size, 110 + icon_size)], radius=32, outline=(255, 255, 255, 60), width=2)

    font_title = get_font(68, bold=True)
    font_sub = get_font(28, bold=False)
    font_desc = get_font(22, bold=False)
    font_pill = get_font(18, bold=True)

    draw.text((120, 290), "Ymac Player", fill=(255, 255, 255, 255), font=font_title)
    draw.text((120, 380), "Minimalist YouTube Music Menu Bar Player", fill=(225, 220, 250, 230), font=font_sub)
    draw.text((120, 425), "& Interactive Desktop Widgets for macOS 26+", fill=(185, 175, 220, 200), font=font_sub)

    draw.text((120, 495), "Seamless background audio, zero ad interruptions, instant hotkeys,", fill=(160, 155, 190, 180), font=font_desc)
    draw.text((120, 530), "Now Playing widgets, and full Apple Silicon & Intel support.", fill=(160, 155, 190, 180), font=font_desc)

    pills = [
        ("macOS 26+ Native", (255, 59, 48)),
        ("Swift 6.0", (240, 81, 56)),
        ("Interactive Widgets", (88, 86, 214)),
        ("AirPlay & Media Keys", (52, 199, 89)),
        ("Gatekeeper Ready", (0, 122, 255)),
    ]

    pill_x = 120
    pill_y = 610
    pill_h = 42
    for label, color in pills:
        tw = draw.textlength(label, font=font_pill)
        pw = int(tw + 36)
        draw.rounded_rectangle([(pill_x, pill_y), (pill_x + pw, pill_y + pill_h)], radius=21, fill=(color[0]//5, color[1]//5, color[2]//5, 220), outline=color, width=1)
        draw.text((pill_x + pw // 2, pill_y + pill_h // 2), label, fill=(255, 255, 255, 240), font=font_pill, anchor="mm")
        pill_x += pw + 16
        if pill_x > 900:
            pill_x = 120
            pill_y += pill_h + 14

    # Right Column: Real Software Showcase
    pop_raw = cut_popover(src)
    pop_scale = 1.45
    pop_w, pop_h = int(pop_raw.width * pop_scale), int(pop_raw.height * pop_scale)
    pop_show = pop_raw.resize((pop_w, pop_h), Image.Resampling.LANCZOS) # ~435 x 577

    crop_med = src.crop((489, 67, 834, 230))
    med_masked = mask_rounded(crop_med, radius=22)
    med_scale = 1.45
    med_w, med_h = int(med_masked.width * med_scale), int(med_masked.height * med_scale)
    med_show = med_masked.resize((med_w, med_h), Image.Resampling.LANCZOS) # ~500 x 236

    crop_small = src.crop((670, 247, 834, 411))
    small_masked = mask_rounded(crop_small, radius=22)
    small_w, small_h = int(small_masked.width * med_scale), int(small_masked.height * med_scale)
    small_show = small_masked.resize((small_w, small_h), Image.Resampling.LANCZOS) # ~237 x 237

    # Position on canvas
    paste_with_shadow(canvas, pop_show, 1180, 140, radius=32, blur=36, offset_y=20, opacity=190)
    paste_with_shadow(canvas, med_show, 1640, 170, radius=36, blur=34, offset_y=18, opacity=180)
    paste_with_shadow(canvas, small_show, 1640 + (med_w - small_w), 170 + med_h + 40, radius=36, blur=30, offset_y=16, opacity=170)

    draw.rectangle([(0, 0), (W - 1, H - 1)], outline=(65, 55, 100, 120), width=2)
    return canvas

def main():
    print(f"Loading source screenshot: {SRC_SCREENSHOT}")
    if not os.path.exists(SRC_SCREENSHOT):
        raise FileNotFoundError(f"Source screenshot not found: {SRC_SCREENSHOT}")
    src = Image.open(SRC_SCREENSHOT).convert('RGBA')

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Generating desktop_widgets.png...")
    widgets_img = build_desktop_widgets_asset(src)
    widgets_path = os.path.join(OUTPUT_DIR, "desktop_widgets.png")
    widgets_img.save(widgets_path, "PNG", optimize=True)
    print(f"Saved: {widgets_path}")

    print("Generating menu_bar_popover.png...")
    pop_img = build_menu_bar_popover_asset(src)
    pop_path = os.path.join(OUTPUT_DIR, "menu_bar_popover.png")
    pop_img.save(pop_path, "PNG", optimize=True)
    print(f"Saved: {pop_path}")

    print("Generating hero_banner.png...")
    banner_img = build_hero_banner_asset(src)
    banner_path = os.path.join(OUTPUT_DIR, "hero_banner.png")
    banner_img.save(banner_path, "PNG", optimize=True)
    print(f"Saved: {banner_path}")

    print("All real assets successfully generated!")

if __name__ == "__main__":
    main()
