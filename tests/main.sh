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
# Get the compressed size of the last build from docker hub
LAST_BUILD_SIZE=$(curl -s https://hub.docker.com/v2/repositories/$IMAGE/tags \
	| jq -r '.results[] | select(.name=="py'"$PY_VER"'-'"$DISTRO"'") | .images[0].size')
SIZE_INCRESE_FACTOR=1.5
SIZE_LIMIT=$(echo "scale=4; $LAST_BUILD_SIZE * $SIZE_INCRESE_FACTOR" | bc)
# Verify size minimal
echo Compressing image for size verification...
docker save $REF | gzip > /tmp/$TAG.tar.gz
SIZE=$(ls -al /tmp | grep $TAG.tar.gz | awk '{ print $5 }')
echo -e \
	Size comparison:\\n\
	Current size: $(numfmt --to iec --format "%8.4f" $SIZE)\\n\
	Last build size:  $(numfmt --to iec --format "%8.4f" $LAST_BUILD_SIZE)\\n\
	Size factor: $SIZE_INCRESE_FACTOR\\n\
	Size limit: $(numfmt --to iec --format "%8.4f" $SIZE_LIMIT)
assert "minimal footprint" "(( $(echo "$SIZE <= $SIZE_LIMIT" | bc -l) ))" $LINENO
rm /tmp/$TAG.tar.gz
# run tests
SHELL_CMD=$(eval "echo \"$SHELL_CMD_TEMPLATE\"")
validate
