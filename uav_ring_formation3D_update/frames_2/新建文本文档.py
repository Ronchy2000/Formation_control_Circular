from PIL import Image, __version__
import os

def resize_and_pad(image, target_size, background_color=(255, 255, 255)):
    """
    Resize an image while maintaining aspect ratio and pad with background color to fit target size.

    :param image: PIL.Image object
    :param target_size: (width, height)
    :param background_color: tuple, background color
    :return: PIL.Image object
    """
    original_size = image.size
    ratio = min(target_size[0] / original_size[0], target_size[1] / original_size[1])
    new_size = (int(original_size[0] * ratio), int(original_size[1] * ratio))
    # Use Resampling.LANCZOS if available, otherwise fallback to LANCZOS
    try:
        resized_image = image.resize(new_size, Image.Resampling.LANCZOS)
    except AttributeError:
        resized_image = image.resize(new_size, Image.LANCZOS)

    new_image = Image.new("RGB", target_size, background_color)
    paste_position = ((target_size[0] - new_size[0]) // 2,
                      (target_size[1] - new_size[1]) // 2)
    new_image.paste(resized_image, paste_position)
    return new_image

def merge_images(image_paths, output_path, rows=4, cols=2, type1_size=(3975, 2103), type2_size=(1000, 800)):
    """
    Merge eight images into a single image with specified rows and columns.

    :param image_paths: list of tuples, each tuple contains (filename, type)
                        type should be 'type1' or 'type2'
    :param output_path: filename for the output image
    :param rows: number of rows in the grid
    :param cols: number of columns in the grid
    :param type1_size: tuple, size for type1 images
    :param type2_size: tuple, size for type2 images
    """
    assert len(image_paths) == rows * cols, "Number of images must match rows*cols"

    processed_images = []
    for filename, img_type in image_paths:
        if not os.path.isfile(filename):
            print(f"文件 {filename} 不存在。")
            return
        img = Image.open(filename).convert("RGB")
        if img_type == 'type1':
            target_size = (1000, 800)  # Resizing type1 to type2 size for uniformity
        elif img_type == 'type2':
            target_size = type2_size
        else:
            print(f"未知的图片类型: {img_type}。请使用 'type1' 或 'type2'。")
            return
        processed_img = resize_and_pad(img, target_size)
        processed_images.append(processed_img)

    # Create a blank canvas
    composite_width = cols * 1000  # Assuming all resized to 1000 width
    composite_height = rows * 800  # Assuming all resized to 800 height
    composite_image = Image.new("RGB", (composite_width, composite_height), (255, 255, 255))

    # Paste images into the composite image
    for idx, img in enumerate(processed_images):
        row = idx // cols
        col = idx % cols
        x = col * 1000
        y = row * 800
        composite_image.paste(img, (x, y))

    # Save the composite image
    composite_image.save(output_path)
    print(f"合并后的图片已保存为 {output_path}")
    

if __name__ == "__main__":
    # 定义八个图片文件名称及其类型
    # 请根据实际情况修改文件名和路径
    image_files = [
        ("takeoff_0001.png", "type2"),
        ("takeoff_0030.png", "type2"),
        ("formation_0080.png", "type2"),
        ("formation_0120.png", "type2"),
        ("formation_0160.png", "type2"),
        ("formation_0200.png", "type2"),
        ("formation_0240.png", "type2"),
        ("formation_0500.png", "type2")
    ]

    # 输出合并后的图片文件名称
    output_file = "AAAAAmerged_image.png"

    # 调用合并函数
    merge_images(image_files, output_file)
