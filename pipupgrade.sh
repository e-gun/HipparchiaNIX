#/bin/bash
./bin/pip install --upgrade pip
./bin/pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 ./bin/pip install -U
