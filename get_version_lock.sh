echo "" > qtile_version.lock
echo "qtile: $( git -C "build/qtile" rev-parse HEAD )" >> qtile_version.lock
echo "qtile-extras: $( git -C "build/qtile-extras" rev-parse HEAD )" >> qtile_version.lock
