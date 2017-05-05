# coding: utf-8
## Resources
require 'sinatra'
require 'open-uri'
require 'feminizer'
require 'nokogiri'
require 'memcached'

ENV['TMPDIR'] ||= '/tmp'
TMPDIR = (ENV['TMPDIR'] =~ /^\/var/ ?
              '/tmp' :
              ENV['TMPDIR'].chomp('/')) + "/artofwomanliness/"

$cache = Memcached.new("#{ENV['MEMCACHED_HOST']}:11211")

## Application

get '/_status' do
  return %Q|{"status": "healthy", "errors": [], "sha": #{sha.inspect}}|
end

get '*' do
  path = request.env['PATH_INFO']
  file_content path
end

def file_content path
  result = cached path
  if result
    puts "Cache hit on #{path}"
    return result
  end
  puts "Cache miss on #{path}"

  content = retrieve path
  content = Feminizer.feminize_html content
  # content = update_hrefs            content
  content = remove_community_link   content
  content = remove_book_promo       content
  content = add_custom_logo         content
  content = tag_with_analytics      content

  unless path =~ /\?random/
    headers['Cache-Control'] = "public; max-age=#{24*60*60}"
  end
  cache path, content
  content
end

def retrieve path
  open("http://artofmanliness.com#{path}", {'User-Agent' => 'Firefox'}).read
end

# This is incomplete - I only want to update hyperlink locations. Perhaps the
# best way is to pass through all resources and update all links.
def update_hrefs html
  html.
    gsub(%r|href='https?://www.artofmanliness.com/|, "href='/").
    gsub(%r|href="https?://www.artofmanliness.com/|, 'href="/')
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

def sha
  File.read('./.git/refs/heads/master').chomp
end

def cached path
  $cache.get "path:#{path}"
rescue Memcached::NotFound
rescue Memcached::ServerIsMarkedDead
end

def cache path, value
  $cache.set "path:#{path}", value, 3600 * 24
  value
rescue Memcached::ServerIsMarkedDead
end
