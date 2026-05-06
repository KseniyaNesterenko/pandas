#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

PROJECT_ROOT=$(pwd)
TEST_DIR="pandas/tests/indexing"

# 1. Формируем список целей
# Мы берем первую часть (до точки) как имя файла, остальное как класс
TESTS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://' | awk -v dir="$TEST_DIR" '{
    n = split($0, parts, ".");
    if (n > 1) {
        # parts[1] - файл, остальное - класс/подмодуль
        # Если есть вложенность (например, multiindex.test_loc)
        # нам нужно превратить это в multiindex/test_loc.py

        path = parts[1];
        class = parts[2];

        # Если частей больше 2, значит первая часть была папкой
        if (n > 2) {
             print dir "/" parts[1] "/" parts[2] ".py::" parts[3]
        } else {
             print dir "/" parts[1] ".py::" parts[2]
        }
    } else {
        print dir "/" $0 ".py"
    }
}')

if [ -z "$TESTS" ] || [ "$TESTS" == "null" ]; then
  echo "No tests found for node $NODE_INDEX"
  exit 0
fi

# 2. Изоляция: переименовываем папку pandas, чтобы не было конфликта импортов
if [ -d "pandas" ]; then
    mv pandas pandas_src
fi

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
echo "TARGETS READY"
echo "-------------------------------------------------------"

# 3. Запуск. Заменяем начальный путь на переименованную папку
echo "$TESTS" | sed 's|^pandas/|pandas_src/|' | xargs python -m pytest --noconftest -p no:warnings -p no:conftest