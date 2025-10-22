#!/usr/bin/env python3
import os
from PIL import Image

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

def generate_icon_from_original(source_png, size, output_path):
    """Generate PNG icon from original PNG at specified size with high quality"""
    try:
        # Open the original image
        with Image.open(source_png) as img:
            # Convert to RGBA if not already
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            # Resize using high-quality LANCZOS resampling
            resized = img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Save with high quality
            resized.save(output_path, 'PNG', optimize=True)
        
        print(f"✅ Generated {output_path} ({size}x{size})")
        return True
    except Exception as e:
        print(f"❌ Error generating {output_path}: {e}")
        return False

def main():
    source_png = "assets/icons/icon_AppStore_1024x1024.png"
    output_dir = "assets/icons"
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    print("🎨 Regenerating iOS app icons from ORIGINAL PNG...")
    print(f"📁 Source: {source_png}")
    print(f"📁 Output: {output_dir}")
    print("-" * 60)
    
    # Check if source file exists
    if not os.path.exists(source_png):
        print(f"❌ Original icon not found: {source_png}")
        return
    
    success_count = 0
    total_count = len(icon_sizes)
    
    for name, size in icon_sizes.items():
        output_path = os.path.join(output_dir, f"icon_{name}_{size}x{size}.png")
        if generate_icon_from_original(source_png, size, output_path):
            success_count += 1
    
    print("-" * 60)
    print(f"📊 Generated {success_count}/{total_count} icons")
    
    if success_count == total_count:
        print("🎉 ALL ICONS GENERATED SUCCESSFULLY!")
        print("🚀 Ready to copy to iOS project!")
    else:
        print("⚠️ Some icons failed to generate")

if __name__ == "__main__":
    main()
