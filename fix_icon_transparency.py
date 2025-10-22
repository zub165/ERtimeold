import os
from PIL import Image

def remove_alpha_channel(source_png_path, output_dir):
    print("🔧 Fixing app icon transparency issue...")
    print("❌ Error: Invalid large app icon - can't be transparent or contain alpha channel")
    print(f"📁 Source: {source_png_path}")
    print(f"📁 Output: {output_dir}")
    print("-" * 60)

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    try:
        source_image = Image.open(source_png_path)
        print(f"✅ Opened source image: {source_image.size}, mode: {source_image.mode}")
        
        # Convert to RGB if it has alpha channel
        if source_image.mode in ('RGBA', 'LA', 'P'):
            print("🔄 Converting from transparent to solid background...")
            # Create a white background
            background = Image.new('RGB', source_image.size, (255, 255, 255))
            if source_image.mode == 'P':
                source_image = source_image.convert('RGBA')
            background.paste(source_image, mask=source_image.split()[-1] if source_image.mode == 'RGBA' else None)
            source_image = background
            print(f"✅ Converted to RGB mode: {source_image.mode}")
        else:
            print(f"✅ Image already in {source_image.mode} mode (no alpha channel)")
            
    except FileNotFoundError:
        print(f"❌ Error: Source PNG file not found at {source_png_path}")
        return
    except Exception as e:
        print(f"❌ Error opening source PNG: {e}")
        return

    icon_sizes = {
        "AppStore_1024x1024": (1024, 1024),
        "iPhone_20_20x20": (20, 20),
        "iPhone_29_29x29": (29, 29),
        "iPhone_40_40x40": (40, 40),
        "iPhone_58_58x58": (58, 58),
        "iPhone_60_60x60": (60, 60),
        "iPhone_76_76x76": (76, 76),
        "iPhone_80_80x80": (80, 80),
        "iPhone_87_87x87": (87, 87),
        "iPhone_120_120x120": (120, 120),
        "iPhone_152_152x152": (152, 152),
        "iPhone_167_167x167": (167, 167),
        "iPhone_180_180x180": (180, 180),
        "iPad_20_20x20": (20, 20),
        "iPad_29_29x29": (29, 29),
        "iPad_40_40x40": (40, 40),
        "iPad_58_58x58": (58, 58),
        "iPad_76_76x76": (76, 76),
        "iPad_80_80x80": (80, 80),
        "iPad_152_152x152": (152, 152),
        "iPad_167_167x167": (167, 167),
        "macOS_16_16x16": (16, 16),
        "macOS_32_32x32": (32, 32),
        "macOS_64_64x64": (64, 64),
        "macOS_128_128x128": (128, 128),
        "macOS_256_256x256": (256, 256),
        "macOS_512_512x512": (512, 512),
    }

    generated_count = 0
    for name, size in icon_sizes.items():
        output_path = os.path.join(output_dir, f"icon_{name}.png")
        try:
            resized_image = source_image.resize(size, Image.LANCZOS)
            # Ensure no alpha channel
            if resized_image.mode in ('RGBA', 'LA', 'P'):
                background = Image.new('RGB', resized_image.size, (255, 255, 255))
                if resized_image.mode == 'P':
                    resized_image = resized_image.convert('RGBA')
                background.paste(resized_image, mask=resized_image.split()[-1] if resized_image.mode == 'RGBA' else None)
                resized_image = background
            
            resized_image.save(output_path, 'PNG')
            print(f"✅ Generated {output_path} ({size[0]}x{size[1]}) - NO ALPHA CHANNEL")
            generated_count += 1
        except Exception as e:
            print(f"❌ Error generating {output_path}: {e}")

    print("-" * 60)
    if generated_count == len(icon_sizes):
        print(f"📊 Generated {generated_count}/{len(icon_sizes)} icons")
        print("🎉 ALL ICONS FIXED - NO TRANSPARENCY!")
        print("🚀 Ready to rebuild IPA!")
    else:
        print(f"Generated {generated_count}/{len(icon_sizes)} icons with some errors.")

if __name__ == "__main__":
    source_png = "assets/icons/icon_AppStore_1024x1024.png"
    output_icons_dir = "assets/icons"
    remove_alpha_channel(source_png, output_icons_dir)
