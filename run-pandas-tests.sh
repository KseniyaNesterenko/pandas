#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Извлекаем тесты
# 2. Убираем "Grouped:"
# 3. Превращаем "test_file.ClassName" в "pandas/tests/indexing/test_file.py::ClassName"
TESTS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://' | awk -F. '{
    if (NF > 1)
        print "pandas/tests/indexing/" $1 ".py::" $2
    else
        print "pandas/tests/indexing/" $1 ".py"
}')

if [ -z "$TESTS" ] || [ "$TESTS" == "null" ]; then
  echo "No tests found for node $NODE_INDEX"
  exit 0
fi

echo "-------------------------------------------------------"
echo "NODE INDEX: $NODE_INDEX"
echo "TARGETS:"
echo "$TESTS"
echo "-------------------------------------------------------"

# Запускаем pytest, передавая список целей как отдельные аргументы
# Мы используем xargs, чтобы pytest корректно воспринял список файлов и классов
echo "$TESTS" | xargs pytest -p no:warnings -p no:conftest