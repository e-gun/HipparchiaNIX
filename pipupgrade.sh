#/bin/bash
# NB matplotlib==3.2.0 breaks networkx
./bin/pip install --upgrade pip
# ./bin/pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 ./bin/pip install -U
./bin/pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | grep -v matplotlib | xargs -n1 ./bin/pip install -U