##############################################################################
# Dockerfile to run iPolex lexical data warehouse
# Based on php
#############################################################################
#
# Build part
#

FROM php:apache

LABEL maintainer="Mathieu.Mangeot@imag.fr"

ARG DICTIONNAIRES_SITE="/var/www/html/Dicos"
ARG DICTIONNAIRES_DAV="/DAV/Dicos"
ARG DICTIONNAIRES_WEB="/Dicos"
ARG DICTIONNAIRES_SITE_PUBLIC="/var/www/html/DicosPublic"
ARG DICTIONNAIRES_WEB_PUBLIC="/DicosPublic"
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

RUN chown www-data:www-data $DICTIONNAIRES_SITE $DICTIONNAIRES_DAV $DICTIONNAIRES_WEB $DICTIONNAIRES_SITE_PUBLIC $DICTIONNAIRES_WEB_PUBLIC

# There is a bug in the openjdk-8-jre install. It stops if the man directory does not exist.
RUN mkdir -p /usr/share/man/man1 \
   && apt-get update && apt-get install -y libexpat1-dev \
      locales \ 
      openjdk-8-jre \

RUN echo 'fr_FR.UTF-8 UTF-8' >> /etc/locale.gen \
   && echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen \
   && locale-gen

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
