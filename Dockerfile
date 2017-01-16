FROM ruby:2.3-alpine

RUN apk add --update \
  build-base \
  libxml2-dev \
  libxslt-dev \
  && rm -rf /var/cache/apk/*

# Use libxml2, libxslt a packages from alpine for building nokogiri
RUN bundle config build.nokogiri --use-system-libraries
RUN gem install bundler

# In case we can ever build the image with some version of the gems available
# this will speed up the CMD considerably.
RUN mkdir -p /tmp/build
COPY Gemfile /tmp/build
RUN cd /tmp/build && bundle

RUN mkdir -p /var/www
WORKDIR /var/www

CMD bundle && bundle exec rackup -p 8080
