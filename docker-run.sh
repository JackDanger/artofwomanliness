#!/bin/sh

docker build . -t artofwomanliness:latest

docker run -it -P -p 8080:8080 -v $(pwd):/var/www artofwomanliness:latest
