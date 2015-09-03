>&2 echo $ITEMS $PWD
cd /usr/mrd
cat 1.out 2.out 3.out > reduce-output
cat 1.stdout 2.stdout 3.stdout >> reduce-output
cat 1.stderr 2.stderr 3.stderr >> reduce-output
cat 1.json
echo
cat 2.json
echo
cat 3.json
