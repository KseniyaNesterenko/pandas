#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Получаем пути
PROJECT_ROOT=$(pwd)
# Папка, где лежат тесты внутри репозитория
TEST_DIR="pandas/tests/indexing"

# 2. Извлекаем тесты и формируем пути относительно текущей папки
# Формат: pandas/tests/indexing/test_file.py::ClassName
TESTS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://' | awk -v dir="$TEST_DIR" -F. '{
    if (NF > 1)
        print dir "/" $1 ".py::" $2
    else
        print dir "/" $1 ".py"
}')

if [ -z "$TESTS" ] || [ "$TESTS" == "null" ]; then
  echo "No tests found for node $NODE_INDEX"
  exit 0
fi

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
echo "RUNNING FROM: $PROJECT_ROOT"
echo "-------------------------------------------------------"

# 3. Запуск через python -m pytest для изоляции
# --noconftest отключает поиск локальных conftest.py, которые вызывают ImportError
# -p no:conftest — дополнительная защита
echo "$TESTS" | xargs python -m pytest --noconftest -p no:warnings -p no:conftest