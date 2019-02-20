FROM php:5-apache

WORKDIR /var/www/html

ADD . .

RUN chmod a+rx index.php
