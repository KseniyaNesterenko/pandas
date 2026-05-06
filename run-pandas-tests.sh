#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Создаем чистую временную папку для тестов
# Это исключит любые конфликты импортов с исходным кодом
mkdir -p isolated_tests

# Копируем только папку с тестами индексации
# Мы делаем это ДО того, как что-то переименуем
cp -r pandas/tests/indexing/* isolated_tests/

# Теперь удаляем папку pandas совсем, чтобы она не смущала Python
rm -rf pandas

# 2. Получаем список групп из JSON
RAW_GROUPS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://')

FINAL_TARGETS=""

for group in $RAW_GROUPS; do
    # Теперь ищем файлы в нашей изолированной папке
    path_with_slashes=$(echo $group | tr '.' '/')

    # Проверка 1: Файл
    if [ -f "isolated_tests/$path_with_slashes.py" ]; then
        FINAL_TARGETS="$FINAL_TARGETS isolated_tests/$path_with_slashes.py"
        continue
    fi

    # Проверка 2: Класс в файле
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
echo "EXECUTING ON ISOLATED TESTS"
echo "-------------------------------------------------------"

# 3. Запуск
# Теперь в текущей папке нет папки pandas, и импорты пойдут из site-packages
python -m pytest --noconftest -p no:warnings -p no:conftest $FINAL_TARGETS