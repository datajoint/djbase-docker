#!/bin/bash

assert ()
{
	E_PARAM_ERR=98
	E_ASSERT_FAILED=99

	if [ -z "$3" ]; then
		return $E_PARAM_ERR
	fi

	lineno=$3
	if ! eval "$2"; then
		echo "Assertion ($1) failed:  \"$2\""
		echo "File \"$0\", line $lineno"
		exit $E_ASSERT_FAILED
	else
		echo "---------------- TEST[$SHELL_CMD_FLAGS]: $1 ✔️ ----------------" | \
			tr -d '\t'
	fi
}
validate () {
	assert "graphviz available" "$SHELL_CMD 'dot -V'" $LINENO
	assert "Arial font available" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		fc-match Arial | wc -l
	END
	) == 1 ]" $LINENO
	assert "datajoint only missing package" "[ $($SHELL_CMD 'eval "$(cat)"' <<-END
		pip install datajoint | grep -i download | wc -l
	END
	) == 1 ]" $LINENO
	assert "import datajoint" "grep -q /opt/conda/lib/python${PY_VER}/site-packages/ <<< \
		$($SHELL_CMD 'eval "$(cat)"' <<-END | tail -1
			pip install datajoint && \
			pip freeze | grep datajoint && \
			python -c 'print(__import__("datajoint").__file__)'
		END
		)" $LINENO
}
# set image context
REF=$(eval "echo $(cat dist/${DISTRO}/docker-compose.yaml | grep 'image:' | \
	awk '{print $2}')")
TAG=$(echo $REF | awk -F':' '{print $2}')
IMAGE=$(echo $REF | awk -F':' '{print $1}')
SHELL_CMD_TEMPLATE="docker run --rm -i \$SHELL_CMD_FLAGS $REF \
	$(docker inspect "$REF" --format '{{join .Config.Cmd " "}}') -c"
# determine reference size
if [ $DISTRO == alpine ] && [ $PY_VER == '3.10' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=741
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.9' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=484
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.8' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=442  # 599
elif [ $DISTRO == alpine ] && [ $PY_VER == '3.7' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=452  # 629
elif [ $DISTRO == debian ] && [ $PY_VER == '3.10' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=879
elif [ $DISTRO == debian ] && [ $PY_VER == '3.9' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=6400
elif [ $DISTRO == debian ] && [ $PY_VER == '3.8' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=599  # 833
elif [ $DISTRO == debian ] && [ $PY_VER == '3.7' ] && [ $PLATFORM == 'linux/amd64' ]; then
	SIZE_LIMIT=597  # 863
fi
SIZE_LIMIT=$(echo "scale=4; $SIZE_LIMIT * 1.06" | bc)
# verify size minimal
SIZE=$(docker images --filter "reference=$REF" --format "{{.Size}}" | awk -F'MB' '{print $1}')
assert "minimal footprint" "(( $(echo "$SIZE <= $SIZE_LIMIT" | bc -l) ))" $LINENO
# run tests
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate
