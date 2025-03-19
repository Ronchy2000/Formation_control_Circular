from PIL import Image
import os

def crop_image(image, crop_left, crop_right):
    """
    Crop the left and right margins of an image.

    :param image: PIL.Image object
    :param crop_left: int, pixels to crop from the left
    :param crop_right: int, pixels to crop from the right
    :return: PIL.Image object
    """
    width, height = image.size
    left = crop_left
    upper = 0
    right = width - crop_right
    lower = height
    cropped_image = image.crop((left, upper, right, lower))
    return cropped_image

def resize_image(image, target_size):
    """
    Resize an image while maintaining aspect ratio.

    :param image: PIL.Image object
    :param target_size: (width, height)
    :return: PIL.Image object
    """
    return image.resize(target_size, Image.LANCZOS)

def pad_image(image, target_size, background_color=(255, 255, 255)):
    """
    Pad an image to fit the target size with a background color, maintaining aspect ratio.

    :param image: PIL.Image object
    :param target_size: (width, height)
    :param background_color: tuple, background color
    :return: PIL.Image object
    """
    original_size = image.size
    ratio = min(target_size[0] / original_size[0], target_size[1] / original_size[1])
    new_size = (int(original_size[0] * ratio), int(original_size[1] * ratio))
    resized_image = image.resize(new_size, Image.LANCZOS)
    
    new_image = Image.new("RGB", target_size, background_color)
    paste_position = ((target_size[0] - new_size[0]) // 2,
                      (target_size[1] - new_size[1]) // 2)
    new_image.paste(resized_image, paste_position)
    return new_image

def process_image(image_path, crop_left, crop_right, target_size, background_color=(255, 255, 255)):
    """
    Crop, resize, and pad an image.

    :param image_path: str, path to the image file
    :param crop_left: int, pixels to crop from the left
    :param crop_right: int, pixels to crop from the right
    :param target_size: (width, height)
    :param background_color: tuple, background color for padding
    :return: PIL.Image object
    """
    try:
        img = Image.open(image_path).convert("RGB")
    except Exception as e:
        print(f"无法打开文件 {image_path}。错误: {e}")
        return None

    # 裁剪左右两边
    cropped_img = crop_image(img, crop_left, crop_right)
    print(f"已裁剪图像 {image_path}，左侧裁剪: {crop_left}px，右侧裁剪: {crop_right}px")

    # 调整大小
    resized_img = resize_image(cropped_img, target_size)
    print(f"已调整图像大小 {image_path} 至 {target_size}")

    # 填充
    padded_img = pad_image(resized_img, target_size, background_color)
    print(f"已填充图像 {image_path} 至 {target_size}，背景色: {background_color}")

    return padded_img

def merge_images(image_paths, output_path, rows=4, cols=2, target_size=(1000, 500), spacing=2, background_color=(255, 255, 255), crop_left=120, crop_right=120):
    """
    Merge images into a single image with specified rows and columns, including spacing between images.
    Each image is first cropped on the left and right, then resized and padded.

    :param image_paths: list of tuples, each tuple contains (filename, type)
                        type should be 'type1' or 'type2'
    :param output_path: str, filename for the output image
    :param rows: int, number of rows in the grid
    :param cols: int, number of columns in the grid
    :param target_size: tuple, size for each image in the grid (width, height)
    :param spacing: int, spacing in pixels between images
    :param background_color: tuple, background color for padding
    :param crop_left: int, pixels to crop from the left side of each image
    :param crop_right: int, pixels to crop from the right side of each image
    """
    assert len(image_paths) == rows * cols, f"Number of images ({len(image_paths)}) must match rows*cols ({rows*cols})"

    processed_images = []
    for idx, (filename, img_type) in enumerate(image_paths):
        if not os.path.isfile(filename):
            print(f"文件 {filename} 不存在。")
            return
        processed_img = process_image(filename, crop_left, crop_right, target_size, background_color)
        if processed_img is not None:
            processed_images.append(processed_img)
        else:
            print(f"图像 {filename} 处理失败，跳过。")

    # 计算合成图像的尺寸，考虑间隔
    composite_width = cols * target_size[0] + (cols - 1) * spacing + 200
    composite_height = rows * target_size[1] + (rows - 1) * spacing
    composite_image = Image.new("RGB", (composite_width, composite_height), background_color)
    print(f"创建合成画布，尺寸: {composite_width}x{composite_height}px，背景色: {background_color}")

    # 将图像粘贴到画布上
    for idx, img in enumerate(processed_images):
        row = idx // cols
        col = idx % cols
        x = col * (target_size[0] + spacing + 200)
        y = row * (target_size[1] + spacing)
        composite_image.paste(img, (x, y))
        print(f"粘贴图像 {idx+1} 到位置: ({x}, {y})")

    # 保存合并后的图像
    try:
        composite_image.save(output_path)
        print(f"合并后的图片已保存为 {output_path}")
    except Exception as e:
        print(f"无法保存合并后的图片。错误: {e}")

if __name__ == "__main__":
    # 定义八个图片文件名称及其类型
    # 请根据实际情况修改文件名和路径
    image_files = [
        ("frame_0001.png", "type1"),
        ("frame_0045.png", "type1"),
        ("frame_0080.png", "type1"),
        ("frame_0175.png", "type1"),
        ("frame_0250.png", "type1"),
        ("frame_0380.png", "type1"),
        ("frame_0490.png", "type1"),
        ("frame_0500.png", "type1")
    ]

    # 输出合并后的图片文件名称
    output_file = "AAAAMerged_image.png"

    # 定义合并图像的总尺寸和间隔
    target_size = (700, 700)  # 每张子图像的目标尺寸 (宽度, 高度)
    spacing = 0  # 图片间隔，减小间隔使画布更小
    crop_left = 700  # 左侧裁剪像素数（根据需要调整）
    crop_right = 700  # 右侧裁剪像素数（根据需要调整）

    # 调用合并函数，设置目标尺寸、间隔和裁剪参数
    merge_images(
        image_files,
        output_file,
        rows=4,
        cols=2,
        target_size=target_size,
        spacing=spacing,
        background_color=(255, 255, 255),
        crop_left=crop_left,
        crop_right=crop_right
    )
