#!/bin/sh

docker build . -t artofwomanliness:latest

docker run -v $(pwd):/var/www artofwomanliness:latest
