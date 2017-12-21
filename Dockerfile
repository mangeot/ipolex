##############################################################################
# Dockerfile to run iPolex lexical data warehouse
# Based on php
#############################################################################
#
# Build part
#

FROM php:apache

LABEL maintainer="Mathieu.Mangeot@imag.fr"

ARG DICTIONNAIRES_SITE="/data/ipolex/"
ARG DICTIONNAIRES_DAV="/var/www/html/Dicos/"
ARG DICTIONNAIRES_WEB="/var/www/html/Dicos/"
ARG DICTIONNAIRES_SITE_PUBLIC="/data/ipolexPublic/"
ARG DICTIONNAIRES_WEB_PUBLIC="/var/www/html/DicosPublic/"
ARG DEFAULT_TEST_USER="mangeot"


ENV DICTIONNAIRES_SITE=$DICTIONNAIRES_SITE
ENV DICTIONNAIRES_DAV=$DICTIONNAIRES_DAV
ENV DICTIONNAIRES_WEB=$DICTIONNAIRES_WEB
ENV DICTIONNAIRES_SITE_PUBLIC=$DICTIONNAIRES_SITE_PUBLIC
ENV DICTIONNAIRES_WEB_PUBLIC=$DICTIONNAIRES_WEB_PUBLIC
ENV DEFAULT_TEST_USER=$DEFAULT_TEST_USER

WORKDIR $DICTIONNAIRES_SITE
WORKDIR $DICTIONNAIRES_DAV
WORKDIR $DICTIONNAIRES_WEB
WORKDIR $DICTIONNAIRES_SITE_PUBLIC
WORKDIR $DICTIONNAIRES_WEB_PUBLIC

# si on veut l'installer manuellement
#RUN curl http://cdn-fastly.deb.debian.org/debian/pool/main/e/expat/libexpat1-dev_2.2.0-2+deb9u1_amd64.deb > libexpat1-dev_2.2.0-2+deb9u1_amd64.deb \
#   && dpkg -i libexpat1-dev_2.2.0-2+deb9u1_amd64.deb

RUN apt-get update && apt-get install -y libexpat1-dev

RUN docker-php-ext-install gettext

RUN cpan install XML::Parser

WORKDIR /var/www/html

COPY . .

RUN cp init.php.sample init.php

RUN sed -i "s#\%DICTIONNAIRES_SITE\%#$DICTIONNAIRES_SITE#g" init.php \ 
   && sed -i "s#\%DICTIONNAIRES_DAV\%#$DICTIONNAIRES_DAV#g" init.php \
   && sed -i "s#\%DICTIONNAIRES_WEB\%#$DICTIONNAIRES_WEB#g" init.php \
   && sed -i "s#\%DICTIONNAIRES_SITE_PUBLIC\%#$DICTIONNAIRES_SITE_PUBLIC#g" init.php \
   && sed -i "s#\%DICTIONNAIRES_WEB_PUBLIC\%#$DICTIONNAIRES_WEB_PUBLIC#g" init.php \
   && sed -i "s#\%DEFAULT_TEST_USER\%#$DEFAULT_TEST_USER#g" init.php
