#!/bin/bash

JSON_FILE=$1
NODE_INDEX=$2

# 1. Пути
PROJECT_ROOT=$(pwd)
TEST_DIR="pandas/tests/indexing"

# 2. Умное формирование путей
# Мы заменяем точки на слэши во всей строке, кроме последнего элемента (который может быть классом)
TESTS=$(jq -r ".containers[$((NODE_INDEX-1))].tests[]" $JSON_FILE | sed 's/Grouped://' | awk -v dir="$TEST_DIR" '{
    # Заменяем точки на слэши, чтобы получить путь к файлу
    gsub(/\./, "/", $1);

    # Теперь нужно проверить: это папка/файл или папка/файл/Класс?
    # В Pandas большинство тестов индексации лежат по пути: dir/имя.py
    # Если это multiindex/test_loc, то путь: dir/multiindex/test_loc.py

    print dir "/" $1 ".py"
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

# Важный хак: удаляем папку с исходниками, чтобы pytest не пытался её импортировать
# Вместо этого он будет использовать установленный 'pip install pandas'
mv pandas pandas_src

# Запускаем pytest, используя новый путь (через pandas_src)
echo "$TESTS" | sed 's/^pandas\//pandas_src\//' | xargs python -m pytest --noconftest -p no:warnings -p no:conftest