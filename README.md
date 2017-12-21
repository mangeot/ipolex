Description
=============

iPolex is a lexical data warehouse. Ressources are described in XML metadata files.
These files can be used for automatic upload into the Jibiki platform.

Installation
=============

The easiest way to install is to use the dockerfiles.

The iPolex dockerfile is built upon php:apache official image: https://hub.docker.com/_/php/

Getting the latest docker image
-------------
    docker pull mangeot/ipolex

Or building from the git repos
-------------
    docker build -t mangeot/ipolex github.com/mangeot/ipolex

Running the docker images
-------------
    docker run --name myipolex -p 8888:80 -d mangeot/ipolex
