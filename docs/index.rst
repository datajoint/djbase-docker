Documentation for the DataJoint's DJBase Image
##############################################

| A minimal base docker image with `DataJoint Python <https://github.com/datajoint/datajoint-python>`_ dependencies installed.
| For more details, have a look at `prebuilt images <https://hub.docker.com/r/datajoint/djbase>`_, `source <https://github.com/datajoint/djbase-docker>`_, and `documentation <https://datajoint.github.io/djbase-docker>`_.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

Launch Locally
**************

Debian
======
.. code-block:: shell

   docker-compose -f dist/debian/docker-compose.yaml --env-file config/.env up --build

Alpine
======
.. code-block:: shell

   docker-compose -f dist/alpine/docker-compose.yaml --env-file config/.env up --build

Features
********

- Installs ``datajoint`` dependencies w/o actually installing ``datajoint``.
- Applies image compresssion.

Testing
*******

To rebuild and run tests locally, execute the following statements:

.. code-block:: shell

   set -a  # automatically export sourced variables
   . config/.env  # source config for build and tests
   docker-compose -f dist/${DISTRO}/docker-compose.yaml build  # build image
   tests/main.sh  # run tests
   set +a  # disable auto-export behavior for sourced variables

Base Image
**********

Build is a child of `datajoint/miniconda3 <https://github.com/datajoint/miniconda3-docker>`_.