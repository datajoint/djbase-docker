ARG BASE_IMAGE_HASH
ARG CONDA_VER
ARG PY_VER
FROM datajoint/miniconda3:${CONDA_VER}-py${PY_VER}-alpine-${BASE_IMAGE_HASH} as py_build

LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"

RUN \
	umask u+rwx,g+rwx,o-rwx && \
	# https://gist.github.com/yuriburger/f13208717b1878fe835346b9871d0ead
	echo "graphviz fontconfig msttcorefonts-installer" | \
		sed 's|\s|\n|g' > $APK_REQUIREMENTS && \
	/entrypoint.sh echo done && \
	export PY_VER=$(python --version 2>&1 | grep -o "\d.\d") && \
	if echo "$PY_VER" | grep -o "3\.9\|3\.8"; then \
		pip install --platform=manylinux1_x86_64 --only-binary=:all: \
			--target=/opt/conda/lib/python${PY_VER}/site-packages \
			--no-cache-dir matplotlib; \
	fi && \
	pip install --no-cache-dir datajoint && \
	pip uninstall datajoint -y && \
	rm $APK_REQUIREMENTS

ENV APK_REQUIREMENTS /tmp/apk_requirements.txt
ENV PIP_REQUIREMENTS /tmp/pip_requirements.txt
ENV CONDA_REQUIREMENTS /tmp/conda_requirements.txt
USER root
RUN \
	# https://gist.github.com/yuriburger/f13208717b1878fe835346b9871d0ead
	update-ms-fonts && \
	fc-cache -f && \
	chmod +x /entrypoint.sh && \
	chmod 4755 /startup
USER anaconda:anaconda
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /main
VOLUME /tmp/.X11-unix
CMD ["sh"]


# Squashed Final Image
FROM scratch
COPY --from=py_build / /
LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"
USER anaconda:anaconda
# Add conda to path here for use in downstream dockerfiles
ENV PATH /opt/conda/bin:$PATH
ENV ENV "/home/anaconda/.ashrc"
ENV HOME /home/anaconda
ENV LANG C.UTF-8
ENV APK_REQUIREMENTS /tmp/apk_requirements.txt
ENV PIP_REQUIREMENTS /tmp/pip_requirements.txt
ENV CONDA_REQUIREMENTS /tmp/conda_requirements.txt
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /main
VOLUME /tmp/.X11-unix
CMD ["sh"]