#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Получаем абсолютный путь к файлу с расписанием, так как мы сменим директорию
ABS_JSON_PATH=$(realpath "$JSON_FILE")
PROJECT_ROOT=$(pwd)

# 2. Извлекаем тесты и формируем пути
# Важно: добавляем имя папки репозитория (обычно 'pandas'), так как мы выйдем на уровень выше
REPO_NAME=$(basename "$PROJECT_ROOT")

TESTS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://' | awk -v repo="$REPO_NAME" -F. '{
    if (NF > 1)
        print repo "/pandas/tests/indexing/" $1 ".py::" $2
    else
        print repo "/pandas/tests/indexing/" $1 ".py"
}')

if [ -z "$TESTS" ] || [ "$TESTS" == "null" ]; then
  echo "No tests found for node $NODE_INDEX"
  exit 0
fi

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
echo "ISOLATED RUN FROM: $(dirname "$PROJECT_ROOT")"
echo "-------------------------------------------------------"

# 3. УХОДИМ из папки проекта уровнем выше
cd ..

# 4. Запускаем pytest, указывая пути относительно текущей (родительской) папки
echo "$TESTS" | xargs pytest -p no:warnings -p no:conftest