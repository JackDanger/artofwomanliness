#!/bin/sh

docker build . -t artofwomanliness:latest

docker run -it -p 8080:8080 -v $(pwd):/var/www artofwomanliness:latest
