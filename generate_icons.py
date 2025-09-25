#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw
import cairosvg
import io

# iOS App Icon sizes required
icon_sizes = {
    # App Store
    'AppStore': 1024,
    
    # iPhone
    'iPhone_20': 20,      # Settings
    'iPhone_29': 29,      # Settings
    'iPhone_40': 40,      # Spotlight
    'iPhone_58': 58,      # Settings @2x
    'iPhone_60': 60,      # Spotlight @3x
    'iPhone_76': 76,      # App @2x
    'iPhone_80': 80,      # Spotlight @2x
    'iPhone_87': 87,      # Settings @3x
    'iPhone_120': 120,    # App @2x
    'iPhone_152': 152,    # App @2x
    'iPhone_167': 167,    # Pro Max App @2x
    'iPhone_180': 180,    # App @3x
    
    # iPad
    'iPad_20': 20,        # Settings
    'iPad_29': 29,        # Settings
    'iPad_40': 40,        # Spotlight
    'iPad_58': 58,        # Settings @2x
    'iPad_76': 76,        # App
    'iPad_80': 80,        # Spotlight @2x
    'iPad_152': 152,      # App @2x
    'iPad_167': 167,      # Pro App @2x
    
    # macOS
    'macOS_16': 16,       # App
    'macOS_32': 32,       # App @2x
    'macOS_64': 64,       # App @2x
    'macOS_128': 128,     # App
    'macOS_256': 256,     # App @2x
    'macOS_512': 512,     # App @2x
}

def generate_icon_from_svg(svg_path, size, output_path):
    """Generate PNG icon from SVG at specified size"""
    try:
        # Convert SVG to PNG
        png_data = cairosvg.svg2png(url=svg_path, output_width=size, output_height=size)
        
        # Save to file
        with open(output_path, 'wb') as f:
            f.write(png_data)
        
        print(f"Generated {output_path} ({size}x{size})")
        return True
    except Exception as e:
        print(f"Error generating {output_path}: {e}")
        return False

def main():
    svg_path = "assets/icon.svg"
    output_dir = "assets/icons"
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    print("Generating iOS app icons...")
    print(f"Source SVG: {svg_path}")
    print(f"Output directory: {output_dir}")
    print("-" * 50)
    
    success_count = 0
    total_count = len(icon_sizes)
    
    for name, size in icon_sizes.items():
        output_path = os.path.join(output_dir, f"icon_{name}_{size}x{size}.png")
        if generate_icon_from_svg(svg_path, size, output_path):
            success_count += 1
    
    print("-" * 50)
    print(f"Successfully generated {success_count}/{total_count} icons")
    
    if success_count == total_count:
        print("✅ All icons generated successfully!")
    else:
        print("❌ Some icons failed to generate")

if __name__ == "__main__":
    main()
