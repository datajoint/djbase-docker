ARG BASE_IMAGE_HASH
ARG CONDA_VER
ARG PY_VER
FROM datajoint/miniconda3:${CONDA_VER}-py${PY_VER}-debian-${BASE_IMAGE_HASH} as py_build

LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"

RUN \
	umask u+rwx,g+rwx,o-rwx && \
	echo 'graphviz' > $APT_REQUIREMENTS && \
	/entrypoint.sh echo done && \
	export PY_VER=$(python --version 2>&1 | grep -o "\d.\d") && \
	if echo "$PY_VER" | grep -oP "3\.9\|3\.8"; then \
		pip install --platform=manylinux1_x86_64 --only-binary=:all: \
			--target=/opt/conda/lib/python${PY_VER}/site-packages \
			--no-cache-dir matplotlib; \
	fi && \
	pip install datajoint --no-cache-dir && \
	pip uninstall datajoint -y && \
	# decorator package had a conflict so installing again to force resolve
	pip install datajoint --no-cache-dir && \
	pip uninstall datajoint -y && \
	rm $APT_REQUIREMENTS

ENV APT_REQUIREMENTS /tmp/apt_requirements.txt
ENV PIP_REQUIREMENTS /tmp/pip_requirements.txt
ENV CONDA_REQUIREMENTS /tmp/conda_requirements.txt
USER root
RUN \
	chmod +x /entrypoint.sh && \
	chmod 4755 /startup
USER anaconda:anaconda
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /main
VOLUME /tmp/.X11-unix
CMD ["bash"]


# Squashed Final Image
FROM scratch
COPY --from=py_build / /
LABEL maintainerName="Raphael Guzman" \
	maintainerEmail="raphael@datajoint.com" \
	maintainerCompany="DataJoint"
USER anaconda:anaconda
ENV PATH /opt/conda/bin:$PATH
ENV HOME /home/anaconda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV APT_REQUIREMENTS /tmp/apt_requirements.txt
ENV PIP_REQUIREMENTS /tmp/pip_requirements.txt
ENV CONDA_REQUIREMENTS /tmp/conda_requirements.txt
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /main
VOLUME /tmp/.X11-unix
CMD ["bash"]