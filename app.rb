# coding: utf-8
## Resources
require 'rubygems' # sorry @defunkt, this is easier
gem 'sinatra', :version => '1.0'
require 'sinatra'
require 'open-uri'
require 'fileutils'
require 'nokogiri'
require 'without_accents'

TMPDIR = (ENV['TMPDIR'] =~ /^\/var/ ?
              '/tmp' :
              ENV['TMPDIR'].chomp('/')) + "/artofwomanliness/"

## Application

get '*' do
  path = request.env['REQUEST_URI']
  file_content path
end

def file_content path

  filename = File.basename(path)
  filename = "/index.html" if path =~ /\/$/

  location = File.expand_path(File.join(TMPDIR, path))

  directory = location.chomp(filename).chomp('/')

  location = File.join(directory, filename)

  # serve from cache
  return File.read(location) if File.exist?(location)


  content = feminize retrieve(path)
  content = tag_with_analytics content

  unless path =~ /\?random/
    FileUtils.mkdir_p(directory)
    File.open(location, 'w') do |f|
      f.write content # write to cache
    end
    headers['Cache-Control'] = "public; max-age=#{24*60*60}"
  end
  content
end

def retrieve path
  response = open("http://artofmanliness.com#{path}", {'User-Agent' => 'Firefox'}).read
end

def feminize content
  tree = Nokogiri::HTML content
  feminize_node! tree
  content = tree.to_html
  content = remove_community_link content
  content = add_custom_logo content
  content
end

def feminize_node! node, indent = 0
  case node.name
  when 'text'
    # print " "*indent
    # puts "feminizing: #{node.content.inspect}"
    node.content = feminize_text(node.content)
    # print " "*indent
    # puts "out: #{node.content.inspect}"
  when 'a'
    # puts "rewriting: #{node.attributes['href'].value}"
    if href = node.attributes['href']
      href.value = href.value.sub(/https?:\/\/artofmanliness.com\/?/, '/')
    end
  else
    # puts 'not processing: '+node.inspect
  end

  if node.children.size > 0
    node.children.each do |child|
    # print " "*indent
    # puts "-> #{child.name}"
      feminize_node! child, indent + 1
    end
  end
end

def feminize_text string
  return string if ['', '\n', "\n"].include?(string.to_s)

  string = string.dup.without_accents

  ok = %Q{([\s"':;\.,\>\<\?\!-])}

  {
    'man' =>         'woman',
    'men' =>         'women',
    'manly' =>       'womanly',
    'manliness' =>   'womanliness',
    'manlier' =>     'womanlier',
    'manliest' =>    'womanliest',
    'manvotional' => 'womanvotional',
    'masculine' =>   'feminine',
    'male' =>        'female',
    'mr.' =>         'ms.',
    'boy' =>         'girl',
    'guy' =>         'girl',
    'dude' =>        'lady',
    'he' =>          'she',
    'his' =>         'her',
    'him' =>         'her',
    'himself' =>     'herself',
    'nobleman' =>    'noblewoman',
    'king' =>        'queen',
    'sissy' =>       'boyish',
    'cowboy' =>      'cowgirl',
    'dad' =>         'mom',
    'daddy' =>       'mommy',
    'dick' =>        'pussy',
    'ex-wife' =>     'ex-husband',
    'father' =>      'mother',
    'fathers' =>     'mothers',
    'brother' =>     'sister',
    'brothers' =>    'sisters'
  }.each do |form, feminine|

    [
      [ form, feminine],
      [ form[0..0].upcase    + form[1..-1],
        feminine[0..0].upcase + feminine[1..-1] ]
    ].each do |pattern, replace|

      string.gsub! %r{#{ok}#{pattern}#{ok}},  '\1'+replace+'\2'
      string.gsub! %r{^#{pattern}#{ok}},      replace+'\1'
      string.gsub! %r{#{ok}#{pattern}$},      '\1'+replace
      string.gsub! %r{^#{pattern}$},          replace
    end
  end
  string
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

def tag_with_analytics html
  html.sub 'UA-1066823-4', 'UA-331450-15'
end
