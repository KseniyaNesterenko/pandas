#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Изоляция
mkdir -p isolated_tests
cp -r pandas/tests/indexing/* isolated_tests/
# Создаем пустой инициализатор, чтобы pytest видел в папке пакет
touch isolated_tests/__init__.py

# УДАЛЯЕМ конфигурационные файлы, которые заставляют pytest капризничать
rm -f pyproject.toml setup.cfg tox.ini
rm -rf pandas

# 2. Собираем цели
RAW_GROUPS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://')

FINAL_TARGETS=""
for group in $RAW_GROUPS; do
    path_with_slashes=$(echo $group | tr '.' '/')

    # Если это файл
    if [ -f "isolated_tests/$path_with_slashes.py" ]; then
        FINAL_TARGETS="$FINAL_TARGETS isolated_tests/$path_with_slashes.py"
        continue
    fi

    # Если это Класс в файле
    base_name="${group%.*}"
    class_name="${group##*.}"
    base_path_slashes=$(echo $base_name | tr '.' '/')

    if [ -f "isolated_tests/$base_path_slashes.py" ]; then
        FINAL_TARGETS="$FINAL_TARGETS isolated_tests/$base_path_slashes.py::$class_name"
        continue
    fi
done

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
echo "EXECUTING ON CLEAN ENVIRONMENT"
echo "-------------------------------------------------------"

# 3. Запуск с подавлением ошибок маркеров
# Мы добавляем -o "markers=filterwarnings" чтобы pytest не падал, встречая этот маркер в коде Pandas
python -m pytest \
    -o "markers=filterwarnings" \
    -p no:warnings \
    --noconftest \
    $FINAL_TARGETS