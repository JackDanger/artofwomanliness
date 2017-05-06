FROM ruby:2.3-alpine

RUN apk add --update \
  build-base \
  libxml2-dev \
  libxslt-dev \
  curl \
  memcached \
  && rm -rf /var/cache/apk/*

# Use libxml2, libxslt a packages from alpine for building nokogiri
RUN gem install bundler
RUN bundle version
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config jobs 10

## In case we can ever build the image with some version of the gems available
## this will speed up the CMD considerably.
RUN mkdir -p /tmp/build
COPY Gemfile /tmp/build
COPY Gemfile.lock /tmp/build
RUN cd /tmp/build && bundle install

RUN mkdir -p /var/www
WORKDIR /var/www

EXPOSE 8080
CMD (bundle check || bundle install) && bundle exec rackup -o 0.0.0.0 -p 8080
