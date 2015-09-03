echo $ITEM > map-output
cat map-output map-input data/hello.txt
>&2 echo $ITEM $ITEMS
if [ "$ITEM" -eq "3" ]; then
  exit 42
fi
if [ "$ITEM" -eq "1" ]; then
  sleep 100
fi
