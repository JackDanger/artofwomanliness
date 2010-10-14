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
  content = remove_book_promo content
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


  forms = {
    'man' =>         'woman',
    'men' =>         'women',
    'manly' =>       'womanly',
    'manliness' =>   'womanliness',
    'manlier' =>     'womanlier',
    'manliest' =>    'womanliest',
    'manhood' =>     'womanhood',
    'manvotional' => 'womanvotional',
    'masculine' =>   'feminine',
    'male' =>        'female',
    'patriarch' =>   'matriarch',
    'mr.' =>         'ms.',
    'boy' =>         'girl',
    'guy' =>         'girl',
    'guys' =>        'girls',
    'dude' =>        'lady',
    'dudes' =>       'ladies',
    'he' =>          'she',
    'his' =>         'her',
    'him' =>         'her',
    'himself' =>     'herself',
    'waitress' =>    'waiter',
    'waitressed' =>  'waited',
    'nobleman' =>    'noblewoman',
    'gentleman' =>   'lady',
    'gentlemen' =>   'ladies',
    'prince' =>      'princess',
    'princes' =>     'princesses',
    'king' =>        'queen',
    'kings' =>       'queens',
    'sissy' =>       'boyish',
    'cowboy' =>      'cowgirl',
    'cowboys' =>     'cowgirls',
    'dad' =>         'mom',
    'daddy' =>       'mommy',
    'dick' =>        'pussy',
    'ex-wife' =>     'ex-husband',
    'father' =>      'mother',
    'fathers' =>     'mothers',
    'brother' =>     'sister',
    'brothers' =>    'sisters'
  }

  forms.each do |masculine, feminine|
    string = string_search_replace(string, feminine, masculine, :mark)
    string = string_search_replace(string, masculine, feminine)
    string = string_search_replace(string, feminine, masculine, :unmark)
  end

  string
end

def string_search_replace(string, from, to, mode = nil)
  ok = %Q{([\s"':;\.,\>\<\?\!-])}
  [
    [ from, to],
    [ from[0..0].upcase  + from[1..-1],
      to[0..0].upcase + to[1..-1] ]
  ].each do |search, replace|
    case mode
    when :mark
      replace = "[marked]#{search}[marked]"
    when :unmark
      search = /\[marked\]#{search}\[marked\]/
    end

    string.gsub! %r{#{ok}#{search}#{ok}},  '\1'+replace+'\2'
    string.gsub! %r{^#{search}#{ok}},      replace+'\1'
    string.gsub! %r{#{ok}#{search}$},      '\1'+replace
    string.gsub! %r{^#{search}$},          replace
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

def remove_book_promo html
  html.sub 'http://content.artofmanliness.com/uploads/bookimages/bookbanner.jpg', '/blank.gif'
end

def tag_with_analytics html
  html.sub 'UA-1066823-4', 'UA-331450-15'
end
