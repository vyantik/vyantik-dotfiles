#!/bin/bash

# Скрипт для обновления цветов в wofi/style.css на основе текущей цветовой схемы Pywal

WAL_COLORS="$HOME/.cache/wal/colors"
WOFI_CSS="$HOME/.config/wofi/style.css"

if [ ! -f "$WAL_COLORS" ]; then
    echo "Файл цветов Pywal не найден: $WAL_COLORS"
    exit 1
fi

# Читаем цвета из файла Pywal
COLOR0=$(sed -n '1p' "$WAL_COLORS")
COLOR1=$(sed -n '2p' "$WAL_COLORS")
COLOR7=$(sed -n '8p' "$WAL_COLORS")
COLOR13=$(sed -n '14p' "$WAL_COLORS")

# Обновляем CSS файл
sed -i "s|#090404|$COLOR0|g" "$WOFI_CSS"
sed -i "s|#2B2B2B|$COLOR1|g" "$WOFI_CSS"
sed -i "s|#c1c0c0|$COLOR7|g" "$WOFI_CSS"
sed -i "s|#565656|$COLOR13|g" "$WOFI_CSS"

echo "Цвета в wofi/style.css обновлены!"
