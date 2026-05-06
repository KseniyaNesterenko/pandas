#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Изоляция (переименовываем, чтобы не было ImportError)
if [ -d "pandas" ]; then
    mv pandas pandas_src
fi

TEST_DIR="pandas_src/tests/indexing"

# 2. Получаем список групп из JSON
RAW_GROUPS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://')

FINAL_TARGETS=""

for group in $RAW_GROUPS; do
    # Пытаемся понять, что это за тест. Варианты:
    # 1. Это просто файл (test_iat)
    # 2. Это файл в подпапке (multiindex.test_getitem)
    # 3. Это класс в файле (test_loc.TestLoc)
    # 4. Это класс в файле в подпапке (multiindex.test_loc.TestMultiIndexLoc)

    # Заменяем точки на слэши для проверки путей
    path_with_slashes=$(echo $group | tr '.' '/')

    # ПРОВЕРКА 1: Это файл в корне indexing или в подпапке?
    if [ -f "$TEST_DIR/$path_with_slashes.py" ]; then
        FINAL_TARGETS="$FINAL_TARGETS $TEST_DIR/$path_with_slashes.py"
        continue
    fi

    # ПРОВЕРКА 2: Это Класс внутри файла? (отрезаем последнюю часть)
    # Например: test_loc.TestLoc -> файл test_loc.py, класс TestLoc
    base_name="${group%.*}" # всё до последней точки
    class_name="${group##*.}" # всё после последней точки
    base_path_slashes=$(echo $base_name | tr '.' '/')

    if [ -f "$TEST_DIR/$base_path_slashes.py" ]; then
        FINAL_TARGETS="$FINAL_TARGETS $TEST_DIR/$base_path_slashes.py::$class_name"
        continue
    fi

    echo "WARNING: Could not resolve test target for group: $group"
done

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
if [ -z "$FINAL_TARGETS" ]; then
    echo "NO VALID TESTS FOUND"
    exit 0
fi
echo "EXECUTING: $FINAL_TARGETS"
echo "-------------------------------------------------------"

# 3. Запуск
# Используем python -m pytest для гарантии использования установленного pandas
python -m pytest --noconftest -p no:warnings -p no:conftest $FINAL_TARGETS