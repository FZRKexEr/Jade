#!/usr/bin/env python3
"""
Chinese Chess macOS App Asset Generator
Creates all visual assets for the Chinese Chess GUI application.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

# Color schemes
COLORS = {
    # Board colors - Wood style
    'wood_light': '#E8D4A2',
    'wood_dark': '#C4A35A',
    'wood_border': '#8B6914',

    # Board colors - Modern style
    'modern_light': '#F5F5F7',
    'modern_dark': '#1C1C1E',
    'modern_accent': '#007AFF',

    # Piece colors - Traditional
    'red_piece': '#CC0000',
    'black_piece': '#1A1A1A',
    'piece_bg': '#F5F0E6',
    'piece_border_red': '#990000',
    'piece_border_black': '#000000',

    # UI colors
    'highlight': '#007AFF',
    'move_indicator': '#34C759',
    'check_warning': '#FF3B30',
    'last_move': '#FF9500',
}

ASSETS_DIR = os.path.dirname(os.path.abspath(__file__))


def save_iconset(image, name, iconset_dir):
    """Save image in all required iconset sizes."""
    sizes = [
        (16, '16x16'),
        (32, '16x16@2x'),
        (32, '32x32'),
        (64, '32x32@2x'),
        (128, '128x128'),
        (256, '128x128@2x'),
        (256, '256x256'),
        (512, '256x256@2x'),
        (512, '512x512'),
        (1024, '512x512@2x'),
    ]

    os.makedirs(iconset_dir, exist_ok=True)

    for size, label in sizes:
        resized = image.resize((size, size), Image.Resampling.LANCZOS)
        filename = f'{name}_{label}.png'
        resized.save(os.path.join(iconset_dir, filename))


def create_rounded_rect(draw, xy, radius, fill, outline=None, width=1):
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = xy
    r = radius

    # Draw main rectangle
    draw.rectangle([x1+r, y1, x2-r, y2], fill=fill)
    draw.rectangle([x1, y1+r, x2, y2-r], fill=fill)

    # Draw corners
    draw.ellipse([x1, y1, x1+2*r, y1+2*r], fill=fill)
    draw.ellipse([x2-2*r, y1, x2, y1+2*r], fill=fill)
    draw.ellipse([x1, y2-2*r, x1+2*r, y2], fill=fill)
    draw.ellipse([x2-2*r, y2-2*r, x2, y2], fill=fill)

    if outline:
        draw.arc([x1, y1, x1+2*r, y1+2*r], 180, 270, fill=outline, width=width)
        draw.arc([x2-2*r, y1, x2, y1+2*r], 270, 360, fill=outline, width=width)
        draw.arc([x1, y2-2*r, x1+2*r, y2], 90, 180, fill=outline, width=width)
        draw.arc([x2-2*r, y2-2*r, x2, y2], 0, 90, fill=outline, width=width)
        draw.line([(x1+r, y1), (x2-r, y1)], fill=outline, width=width)
        draw.line([(x1+r, y2), (x2-r, y2)], fill=outline, width=width)
        draw.line([(x1, y1+r), (x1, y2-r)], fill=outline, width=width)
        draw.line([(x2, y1+r), (x2, y2-r)], fill=outline, width=width)


def create_app_icon():
    """Create the main application icon."""
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background - rounded square with gradient
    bg_color = '#2C2C2E'
    corner_radius = 200

    # Create gradient background
    for y in range(size):
        progress = y / size
        r = int(44 + (60 - 44) * progress)
        g = int(44 + (60 - 44) * progress)
        b = int(46 + (64 - 46) * progress)
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    # Mask for rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size, size], radius=corner_radius, fill=255)

    # Apply background with mask
    bg = Image.new('RGBA', (size, size))
    for y in range(size):
        for x in range(size):
            bg.putpixel((x, y), img.getpixel((x, y)))

    # Draw the chess piece (red "帅" - commander)
    piece_center = (size // 2, size // 2)
    piece_radius = 280

    # Outer red circle (piece border)
    draw.ellipse(
        [piece_center[0] - piece_radius, piece_center[1] - piece_radius,
         piece_center[0] + piece_radius, piece_center[1] + piece_radius],
        fill='#CC0000', outline='#990000', width=8
    )

    # Inner circle (piece background)
    inner_radius = 240
    draw.ellipse(
        [piece_center[0] - inner_radius, piece_center[1] - inner_radius,
         piece_center[0] + inner_radius, piece_center[1] + inner_radius],
        fill='#F5F0E6'
    )

    # Draw "帅" character
    try:
        # Try to use system font
        font_size = 240
        font = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", font_size)
        except:
            font = ImageFont.load_default()

    text = "帅"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = piece_center[0] - text_width // 2 - bbox[0]
    text_y = piece_center[1] - text_height // 2 - bbox[1] - 10

    draw.text((text_x, text_y), text, font=font, fill='#CC0000')

    # Apply rounded mask to final image
    final_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final_img.paste(img, (0, 0), mask)

    # Save app icon
    iconset_dir = os.path.join(ASSETS_DIR, 'Icons', 'AppIcon.iconset')
    save_iconset(final_img, 'AppIcon', iconset_dir)

    # Also save a combined 1024x1024 version
    final_img.save(os.path.join(ASSETS_DIR, 'Icons', 'AppIcon_1024.png'))

    print(f"App icon created at: {iconset_dir}")
    return final_img


def create_board_styles():
    """Create different board style textures."""
    board_dir = os.path.join(ASSETS_DIR, 'BoardStyles')

    # Wood style board
    size = 1024
    wood_img = Image.new('RGB', (size, size), '#E8D4A2')
    draw = ImageDraw.Draw(wood_img)

    # Add wood grain texture
    import random
    random.seed(42)  # For reproducibility

    for _ in range(5000):
        x = random.randint(0, size-1)
        y = random.randint(0, size-1)
        length = random.randint(20, 100)
        color_var = random.randint(-20, 20)
        base_color = (232, 212, 162)
        color = tuple(max(0, min(255, c + color_var)) for c in base_color)
        draw.line([(x, y), (x, y+length)], fill=color, width=1)

    # Draw board grid lines
    margin = 80
    grid_size = size - 2 * margin
    line_color = '#5C4033'

    # Horizontal lines
    for i in range(10):
        y = margin + i * grid_size // 9
        draw.line([(margin, y), (size - margin, y)], fill=line_color, width=2)

    # Vertical lines
    for i in range(9):
        x = margin + i * grid_size // 8
        draw.line([(x, margin), (x, margin + 4 * grid_size // 9)], fill=line_color, width=2)
        draw.line([(x, margin + 5 * grid_size // 9), (x, size - margin)], fill=line_color, width=2)

    # Draw palace diagonals
    palace_margin_x = margin + 3 * grid_size // 8
    palace_width = 2 * grid_size // 8
    palace_top = margin
    palace_bottom = margin + 4 * grid_size // 9
    palace_mid_top = margin + 5 * grid_size // 9
    palace_mid_bottom = size - margin

    # Top palace
    draw.line([(palace_margin_x, palace_top), (palace_margin_x + palace_width, palace_bottom)], fill=line_color, width=2)
    draw.line([(palace_margin_x + palace_width, palace_top), (palace_margin_x, palace_bottom)], fill=line_color, width=2)

    # Bottom palace
    draw.line([(palace_margin_x, palace_mid_bottom), (palace_margin_x + palace_width, palace_mid_top)], fill=line_color, width=2)
    draw.line([(palace_margin_x + palace_width, palace_mid_bottom), (palace_margin_x, palace_mid_top)], fill=line_color, width=2)

    wood_img.save(os.path.join(board_dir, 'Board_Wood.png'))

    # Modern light style
    modern_light = Image.new('RGB', (size, size), '#F5F5F7')
    draw = ImageDraw.Draw(modern_light)

    # Draw grid
    line_color = '#8E8E93'
    for i in range(10):
        y = margin + i * grid_size // 9
        draw.line([(margin, y), (size - margin, y)], fill=line_color, width=1)

    for i in range(9):
        x = margin + i * grid_size // 8
        draw.line([(x, margin), (x, margin + 4 * grid_size // 9)], fill=line_color, width=1)
        draw.line([(x, margin + 5 * grid_size // 9), (x, size - margin)], fill=line_color, width=1)

    # Palace diagonals
    draw.line([(palace_margin_x, palace_top), (palace_margin_x + palace_width, palace_bottom)], fill=line_color, width=1)
    draw.line([(palace_margin_x + palace_width, palace_top), (palace_margin_x, palace_bottom)], fill=line_color, width=1)
    draw.line([(palace_margin_x, palace_mid_bottom), (palace_margin_x + palace_width, palace_mid_top)], fill=line_color, width=1)
    draw.line([(palace_margin_x + palace_width, palace_mid_bottom), (palace_margin_x, palace_mid_top)], fill=line_color, width=1)

    modern_light.save(os.path.join(board_dir, 'Board_Modern_Light.png'))

    # Modern dark style
    modern_dark = Image.new('RGB', (size, size), '#1C1C1E')
    draw = ImageDraw.Draw(modern_dark)

    line_color = '#636366'
    for i in range(10):
        y = margin + i * grid_size // 9
        draw.line([(margin, y), (size - margin, y)], fill=line_color, width=1)

    for i in range(9):
        x = margin + i * grid_size // 8
        draw.line([(x, margin), (x, margin + 4 * grid_size // 9)], fill=line_color, width=1)
        draw.line([(x, margin + 5 * grid_size // 9), (x, size - margin)], fill=line_color, width=1)

    # Palace diagonals
    draw.line([(palace_margin_x, palace_top), (palace_margin_x + palace_width, palace_bottom)], fill=line_color, width=1)
    draw.line([(palace_margin_x + palace_width, palace_top), (palace_margin_x, palace_bottom)], fill=line_color, width=1)
    draw.line([(palace_margin_x, palace_mid_bottom), (palace_margin_x + palace_width, palace_mid_top)], fill=line_color, width=1)
    draw.line([(palace_margin_x + palace_width, palace_mid_bottom), (palace_margin_x, palace_mid_top)], fill=line_color, width=1)

    modern_dark.save(os.path.join(board_dir, 'Board_Modern_Dark.png'))

    print(f"Board styles created in: {board_dir}")


def create_pieces():
    """Create traditional and modern style pieces."""
    piece_dir = os.path.join(ASSETS_DIR, 'PieceStyles')

    # Piece names
    red_pieces = ['帅', '仕', '相', '傌', '俥', '炮', '兵']
    black_pieces = ['将', '士', '象', '马', '车', '砲', '卒']

    sizes = [64, 128, 256]

    for size in sizes:
        # Traditional style
        trad_dir = os.path.join(piece_dir, 'Traditional', str(size))
        os.makedirs(trad_dir, exist_ok=True)

        for i, (red_char, black_char) in enumerate(zip(red_pieces, black_pieces)):
            # Red piece
            img = create_traditional_piece(size, red_char, 'red')
            img.save(os.path.join(trad_dir, f'Red_{i}.png'))

            # Black piece
            img = create_traditional_piece(size, black_char, 'black')
            img.save(os.path.join(trad_dir, f'Black_{i}.png'))

        # Modern style
        modern_dir = os.path.join(piece_dir, 'Modern', str(size))
        os.makedirs(modern_dir, exist_ok=True)

        for i, (red_char, black_char) in enumerate(zip(red_pieces, black_pieces)):
            # Red piece
            img = create_modern_piece(size, red_char, 'red')
            img.save(os.path.join(modern_dir, f'Red_{i}.png'))

            # Black piece
            img = create_modern_piece(size, black_char, 'black')
            img.save(os.path.join(modern_dir, f'Black_{i}.png'))

    print(f"Pieces created in: {piece_dir}")


def create_traditional_piece(size, char, color):
    """Create a traditional style piece."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size // 2
    radius = int(size * 0.45)

    # Colors
    if color == 'red':
        border_color = '#CC0000'
        bg_color = '#F5F0E6'
        text_color = '#CC0000'
    else:
        border_color = '#1A1A1A'
        bg_color = '#F5F0E6'
        text_color = '#1A1A1A'

    # Outer border (thicker)
    draw.ellipse(
        [center - radius - 2, center - radius - 2,
         center + radius + 2, center + radius + 2],
        fill=border_color
    )

    # Inner background
    draw.ellipse(
        [center - radius, center - radius,
         center + radius, center + radius],
        fill=bg_color
    )

    # Character
    try:
        font_size = int(size * 0.55)
        # Try different font paths
        font_paths = [
            "/System/Library/Fonts/STHeiti Light.ttc",
            "/System/Library/Fonts/PingFang.ttc",
            "/System/Library/Fonts/Hiragino Sans GB.ttc",
        ]
        font = None
        for path in font_paths:
            if os.path.exists(path):
                try:
                    font = ImageFont.truetype(path, font_size)
                    break
                except:
                    continue
        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    # Get text bounding box
    bbox = draw.textbbox((0, 0), char, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = center - text_width // 2 - bbox[0]
    text_y = center - text_height // 2 - bbox[1] - size * 0.05

    draw.text((text_x, text_y), char, font=font, fill=text_color)

    return img


def create_modern_piece(size, char, color):
    """Create a modern flat style piece."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size // 2
    radius = int(size * 0.42)

    # Colors - modern flat style
    if color == 'red':
        bg_color = '#FF3B30'
        text_color = '#FFFFFF'
        shadow_color = '#CC2E24'
    else:
        bg_color = '#1C1C1E'
        text_color = '#FFFFFF'
        shadow_color = '#000000'

    # Shadow (offset)
    shadow_offset = int(size * 0.03)
    draw.ellipse(
        [center - radius + shadow_offset, center - radius + shadow_offset,
         center + radius + shadow_offset, center + radius + shadow_offset],
        fill=shadow_color
    )

    # Main circle
    draw.ellipse(
        [center - radius, center - radius,
         center + radius, center + radius],
        fill=bg_color
    )

    # Character
    try:
        font_size = int(size * 0.5)
        font_paths = [
            "/System/Library/Fonts/STHeiti Light.ttc",
            "/System/Library/Fonts/PingFang.ttc",
            "/System/Library/Fonts/Hiragino Sans GB.ttc",
        ]
        font = None
        for path in font_paths:
            if os.path.exists(path):
                try:
                    font = ImageFont.truetype(path, font_size)
                    break
                except:
                    continue
        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), char, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = center - text_width // 2 - bbox[0]
    text_y = center - text_height // 2 - bbox[1] - size * 0.05

    draw.text((text_x, text_y), char, font=font, fill=text_color)

    return img


def create_toolbar_icons():
    """Create toolbar icons for the application."""
    toolbar_dir = os.path.join(ASSETS_DIR, 'Toolbar')
    os.makedirs(toolbar_dir, exist_ok=True)

    icons = {
        'NewGame': ('new', '#007AFF'),
        'Undo': ('undo', '#5856D6'),
        'Hint': ('hint', '#FF9500'),
        'Settings': ('settings', '#8E8E93'),
        'Analysis': ('analysis', '#34C759'),
    }

    sizes = [18, 24, 36]

    for icon_name, (icon_type, color) in icons.items():
        for size in sizes:
            img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            draw = ImageDraw.Draw(img)

            center = size // 2
            stroke = max(1, size // 12)

            if icon_type == 'new':
                # Plus icon
                draw.line([(center, stroke), (center, size-stroke)], fill=color, width=stroke)
                draw.line([(stroke, center), (size-stroke, center)], fill=color, width=stroke)

            elif icon_type == 'undo':
                # Curved arrow back
                arc_radius = size // 3
                # Draw arc
                draw.arc([center - arc_radius, center - arc_radius,
                         center + arc_radius, center + arc_radius],
                        start=200, end=340, fill=color, width=stroke)
                # Arrow head
                arrow_x = center - arc_radius
                arrow_y = center
                draw.polygon([(arrow_x, arrow_y), (arrow_x + stroke*2, arrow_y - stroke),
                             (arrow_x + stroke*2, arrow_y + stroke)], fill=color)

            elif icon_type == 'hint':
                # Lightbulb
                bulb_radius = size // 3
                draw.ellipse([center - bulb_radius, center - bulb_radius - stroke,
                             center + bulb_radius, center + bulb_radius - stroke],
                            fill=color, outline=color)
                # Base
                draw.rectangle([center - stroke, center + stroke,
                               center + stroke, center + bulb_radius + stroke*2],
                              fill=color)

            elif icon_type == 'settings':
                # Gear (simplified as circle with dots)
                gear_radius = size // 3
                draw.ellipse([center - gear_radius, center - gear_radius,
                             center + gear_radius, center + gear_radius],
                            outline=color, width=stroke)
                # Center dot
                draw.ellipse([center - stroke, center - stroke,
                             center + stroke, center + stroke],
                            fill=color)

            elif icon_type == 'analysis':
                # Graph/chart icon
                # Axes
                draw.line([(stroke*2, size-stroke*2), (stroke*2, stroke*2)], fill=color, width=stroke)
                draw.line([(stroke*2, size-stroke*2), (size-stroke*2, size-stroke*2)], fill=color, width=stroke)
                # Trend line
                points = [(stroke*4, size-stroke*4), (size//3, size//2),
                         (size//2, size//3), (size-stroke*4, stroke*4)]
                draw.line(points, fill=color, width=stroke)

            # Save at 1x and 2x
            scale_suffix = '' if size <= 24 else '@2x'
            save_size = size if size <= 24 else size // 2
            img.save(os.path.join(toolbar_dir, f'{icon_name}_{save_size}x{save_size}{scale_suffix}.png'))

    print(f"Toolbar icons created in: {toolbar_dir}")


def create_ui_elements():
    """Create UI elements like selection indicators."""
    ui_dir = os.path.join(ASSETS_DIR, 'UI')
    os.makedirs(ui_dir, exist_ok=True)

    size = 256

    # Selection highlight
    selection = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(selection)
    center = size // 2
    radius = size // 2 - 10

    # Glowing ring
    for i in range(10, 0, -1):
        alpha = int(50 - i * 4)
        draw.ellipse(
            [center - radius - i, center - radius - i,
             center + radius + i, center + radius + i],
            outline=(0, 122, 255, alpha), width=2
        )

    selection.save(os.path.join(ui_dir, 'Selection_Highlight.png'))

    # Move indicator (dot)
    move_dot = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(move_dot)

    dot_radius = size // 6
    draw.ellipse(
        [center - dot_radius, center - dot_radius,
         center + dot_radius, center + dot_radius],
        fill=(52, 199, 89, 180)
    )

    move_dot.save(os.path.join(ui_dir, 'Move_Indicator.png'))

    # Check warning (pulsing effect)
    check_warning = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(check_warning)

    radius = size // 2 - 10
    for i in range(5, 0, -1):
        alpha = int(100 - i * 15)
        draw.ellipse(
            [center - radius - i*3, center - radius - i*3,
             center + radius + i*3, center + radius + i*3],
            outline=(255, 59, 48, alpha), width=3
        )

    check_warning.save(os.path.join(ui_dir, 'Check_Warning.png'))

    # Last move indicator
    last_move = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(last_move)

    # Subtle border
    radius = size // 2 - 5
    draw.ellipse(
        [center - radius, center - radius,
         center + radius, center + radius],
        outline=(255, 149, 0, 150), width=3
    )

    last_move.save(os.path.join(ui_dir, 'Last_Move_Indicator.png'))

    print(f"UI elements created in: {ui_dir}")


def main():
    """Generate all assets."""
    print("Starting asset generation...")

    # Create app icon
    print("\n1. Creating app icon...")
    create_app_icon()

    # Create board styles
    print("\n2. Creating board styles...")
    create_board_styles()

    # Create pieces
    print("\n3. Creating pieces...")
    create_pieces()

    # Create toolbar icons
    print("\n4. Creating toolbar icons...")
    create_toolbar_icons()

    # Create UI elements
    print("\n5. Creating UI elements...")
    create_ui_elements()

    # Create launch screen
    print("\n6. Creating launch screen...")
    create_launch_screen()

    print("\n✅ All assets generated successfully!")


def create_launch_screen():
    """Create launch screen for the application."""
    launch_dir = os.path.join(ASSETS_DIR, 'LaunchScreen')
    os.makedirs(launch_dir, exist_ok=True)

    # Create launch screen at common macOS window sizes
    sizes = [
        (800, 600, 'LaunchScreen_800x600'),
        (1024, 768, 'LaunchScreen_1024x768'),
        (1200, 800, 'LaunchScreen_1200x800'),
        (1600, 1000, 'LaunchScreen_1600x1000'),
    ]

    for width, height, name in sizes:
        img = Image.new('RGB', (width, height), '#F5F5F7')
        draw = ImageDraw.Draw(img)

        center_x = width // 2
        center_y = height // 2

        # Draw a large decorative piece in the center
        piece_radius = min(width, height) // 8

        # Outer red circle
        draw.ellipse(
            [center_x - piece_radius, center_y - piece_radius - 40,
             center_x + piece_radius, center_y + piece_radius - 40],
            fill='#CC0000', outline='#990000', width=4
        )

        # Inner background
        inner_radius = int(piece_radius * 0.85)
        draw.ellipse(
            [center_x - inner_radius, center_y - inner_radius - 40,
             center_x + inner_radius, center_y + inner_radius - 40],
            fill='#F5F0E6'
        )

        # Try to draw the character
        try:
            font_size = int(piece_radius * 1.2)
            font_paths = [
                "/System/Library/Fonts/STHeiti Light.ttc",
                "/System/Library/Fonts/PingFang.ttc",
                "/System/Library/Fonts/Hiragino Sans GB.ttc",
            ]
            font = None
            for path in font_paths:
                if os.path.exists(path):
                    try:
                        font = ImageFont.truetype(path, font_size)
                        break
                    except:
                        continue
            if font is None:
                font = ImageFont.load_default()
        except:
            font = ImageFont.load_default()

        text = "棋"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_x = center_x - text_width // 2 - bbox[0]
        text_y = center_y - text_height // 2 - bbox[1] - 40

        draw.text((text_x, text_y), text, font=font, fill='#CC0000')

        # Add app name below
        try:
            name_font = ImageFont.truetype("/System/Library/Fonts/SFProDisplay-Semibold.otf", 36)
        except:
            try:
                name_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
            except:
                name_font = ImageFont.load_default()

        app_name = "Chinese Chess"
        bbox = draw.textbbox((0, 0), app_name, font=name_font)
        name_width = bbox[2] - bbox[0]
        name_x = center_x - name_width // 2
        name_y = center_y + piece_radius + 20

        draw.text((name_x, name_y), app_name, font=name_font, fill='#1C1C1E')

        # Save
        img.save(os.path.join(launch_dir, f'{name}.png'))

    print(f"Launch screen created at: {launch_dir}")


if __name__ == '__main__':
    main()
