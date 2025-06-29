#!/usr/bin/env python3

import json
import os

# Путь к файлу colors.json, генерируемому pywal
WAL_COLORS_FILE = os.path.expanduser('~/.cache/wal/colors.json')
# Путь, куда будет записана часть конфига Hyprland
HYPRLAND_COLORS_CONFIG = os.path.expanduser('~/.config/hypr/colors.conf')


def hex_to_rgba(hex_color, alpha_hex="FF"):
    """Converts a hex color (#RRGGBB) to rgba(RRGGBBAA) format."""
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 6:
        return f"rgba({hex_color}{alpha_hex})"
    elif len(hex_color) == 8:  # Already has alpha
        return f"rgba({hex_color})"
    return "rgba(000000FF)"  # Default if invalid


try:
    with open(WAL_COLORS_FILE, 'r') as f:
        wal_data = json.load(f)

    # Извлекаем нужные цвета
    # Здесь вы можете выбрать любые цвета из wal_data['colors']
    # Например, @color9 из вашей Waybar темы или background/foreground
    background = wal_data['special']['background']
    foreground = wal_data['special']['foreground']
    color0 = wal_data['colors']['color0']
    color7 = wal_data['colors']['color7']
    color9 = wal_data['colors']['color9']  # Это @mauve / @red из Waybar
    # Часто используется как более тусклый серый/фон
    color8 = wal_data['colors']['color8']

    # Какие цвета вы хотите использовать для бордеров
    # Пример: активный бордюр - @color9
    # неактивный бордюр - @background или @color8
    active_border_color_hex = color9
    inactive_border_color_hex = color8
    # Или background, если хотите очень темный

    # Преобразуем в формат RGBA. Вы можете настроить прозрачность (AA).
    # Например, для активного можно сделать градиент или не много альфа
    active_border_rgba_1 = hex_to_rgba(
        active_border_color_hex, "EE")  # 93% opaque
    active_border_rgba_2 = hex_to_rgba(
        active_border_color_hex, "AA")  # 67% opaque (для градиента)
    inactive_border_rgba = hex_to_rgba(
        inactive_border_color_hex, "AA")  # 67% opaque

    # Создаем содержимое файла colors.conf
    config_content = f"""
#This file is auto-generated by set_wal_colors.py
#DO NOT EDIT MANUALLY!

general {{
    col.active_border = {active_border_rgba_1} {active_border_rgba_2} 45deg
    col.inactive_border = {inactive_border_rgba}
}}
    """
    with open(HYPRLAND_COLORS_CONFIG, 'w') as f:
        f.write(config_content.strip())
        print(f"Generated {HYPRLAND_COLORS_CONFIG} with colors from pywal.")
except FileNotFoundError:
    print(f"Error: {WAL_COLORS_FILE} not found. Run pywal first.")
except Exception as e:
    print(f"An error occurred: {e}")
