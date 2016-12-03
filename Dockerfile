FROM ruby:2.3-alpine

RUN apk add --update \
  build-base \
  libxml2-dev \
  libxslt-dev \
  && rm -rf /var/cache/apk/*

# Use libxml2, libxslt a packages from alpine for building nokogiri
RUN bundle config build.nokogiri --use-system-libraries

RUN mkdir -p /var/www
RUN cd /var/www && gem install bundler

CMD cd /var/www && bundle && bundle exec rackup -p 8080
