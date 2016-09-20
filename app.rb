# coding: utf-8
## Resources
require 'sinatra'
require 'open-uri'
require 'feminizer'
require 'nokogiri'
require 'without_accents'

ENV['TMPDIR'] ||= '/tmp'
TMPDIR = (ENV['TMPDIR'] =~ /^\/var/ ?
              '/tmp' :
              ENV['TMPDIR'].chomp('/')) + "/artofwomanliness/"

## Application

get '*' do
  path = request.env['PATH_INFO']
  file_content path
end

def file_content path

  content = retrieve path
  content = Feminizer.feminize_html content
  content = remove_community_link   content
  content = remove_book_promo       content
  content = add_custom_logo         content
  content = tag_with_analytics      content

  unless path =~ /\?random/
    headers['Cache-Control'] = "public; max-age=#{24*60*60}"
  end
  content
end

def retrieve path
  open("http://artofmanliness.com#{path}", {'User-Agent' => 'Firefox'}).read
end

def add_custom_logo html
  html.sub '<div id="header">',
           '<div id="header" style="background-image: url(/header1.jpg);">'
  
end

def remove_community_link html
  html.
    sub('<li><a href="http://community.artofmanliness.com">Community</a></li>', '').
    sub('<li><a href="http://community.artofmanliness.com" title="Join the AoM Community">Community</a></li>', '')
end

def remove_book_promo html
  html.sub 'http://content.artofmanliness.com/uploads/bookimages/bookbanner.jpg', '/blank.gif'
end

def tag_with_analytics html
  html.sub 'UA-1066823-4', 'UA-331450-15'
end
