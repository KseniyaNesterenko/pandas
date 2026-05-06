#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Подготовка папки (Изоляция)
if [ -d "pandas" ]; then
    mv pandas pandas_src
fi

TEST_DIR="pandas_src/tests/indexing"

# 2. Умное формирование путей
# Мы берем строку "multiindex.test_setitem"
# И пробуем превратить её в "multiindex/test_setitem.py"
TESTS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://' | awk -v dir="$TEST_DIR" '{
    # Заменяем все точки на слэши
    path = $0;
    gsub(/\./, "/", path);

    # 1. Проверяем формат: папка/файл.py (например, multiindex/test_setitem.py)
    file_path = dir "/" path ".py";

    # 2. Проверяем формат: папка/файл.py::Класс
    # Для этого берем всё до последнего слэша как путь, а последний элемент как класс
    split(path, parts, "/");
    if (length(parts) > 1) {
        base_path = "";
        for (i=1; i<length(parts); i++) {
            base_path = (i==1) ? parts[i] : base_path "/" parts[i];
        }
        class_path = dir "/" base_path ".py::" parts[length(parts)];
    } else {
        class_path = dir "/" path ".py";
    }

    print file_path " " class_path
}')

if [ -z "$TESTS" ] || [ "$TESTS" == "null" ]; then
  echo "No tests found for node $NODE_INDEX"
  exit 0
fi

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
echo "-------------------------------------------------------"

# 3. Запуск Pytest с проверкой существования
FINAL_TARGETS=""
for pair in $TESTS; do
    # pair содержит два варианта, разделенных пробелом.
    # Проверяем первый (как файл)
    FILE_ONLY=$(echo $pair | cut -d' ' -f1)
    if [ -f "$FILE_ONLY" ]; then
        FINAL_TARGETS="$FINAL_TARGETS $FILE_ONLY"
    else
        # Если файла нет, значит это был Класс (второй вариант)
        CLASS_TARGET=$(echo $pair | cut -d' ' -f2)
        FINAL_TARGETS="$FINAL_TARGETS $CLASS_TARGET"
    fi
done

echo "EXECUTING: $FINAL_TARGETS"

python -m pytest --noconftest -p no:warnings -p no:conftest $FINAL_TARGETS