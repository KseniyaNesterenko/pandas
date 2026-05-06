#!/bin/bash

if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it."
    exit 1
fi

JSON_FILE=$1
NODE_INDEX=$2

# Извлекаем тесты, убираем префикс "Grouped:" и заменяем точки на слэши для путей
# (Для пандаса test_categorical.TestCategoricalIndex превратится в pandas/tests/indexing/test_categorical.py)
TESTS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://' | sed 's/\./\//' | sed 's/$/.py/')

if [ -z "$TESTS" ] || [ "$TESTS" == "null" ]; then
  echo "No tests found for node $NODE_INDEX"
  exit 0
fi

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
echo "RUNNING TESTS: $TESTS"
echo "-------------------------------------------------------"

# Запускаем pytest.
# Мы используем -p no:conftest, как и раньше, чтобы избежать проблем с импортами в CI
PYTHONPATH=. pytest -p no:warnings -p no:conftest $TESTS