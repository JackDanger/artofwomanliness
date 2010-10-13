## Resources
require 'rubygems' # sorry @defunkt, this is easier
gem 'sinatra', :version => '1.0'
require 'open-uri'
require 'fileutils'
require 'nokogiri'
require 'sinatra'
require 'active_record'
require 'without_accents'
gem 'alphadecimal'
require 'alphadecimal'

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
  puts "filename1: #{filename}"
  filename = "/index.html" if path =~ /\/$/
  puts "filename: #{filename}"

  location = File.expand_path(File.join(TMPDIR, path))

  directory = location.chomp(filename).chomp('/')
  FileUtils.mkdir_p(directory)

  location = File.join(directory, filename)
  puts "location!: #{location}"

  # return File.read(location) if File.exist?(location)


  content = transform path
  puts "content: #{content}"
  File.open(location, 'w') do |f|
    f.write content
  end
  content
end

def transform path
  case path
  when /(.jpg|.ico|.gif|.png|.css|.txt|.js)$/,
       /(.jpg|.ico|.gif|.png|.css|.txt|.js)\?/
    puts "passthrough: #{path}"
    headers['Content-Type'] = request.env['Content-Type']
    retrieve path
  else
    puts "feminize: #{path}"
    feminize retrieve(path)
  end
end

def retrieve path
  open("http://artofmanliness.com#{path}", {'User-Agent' => 'Firefox'}).read
end

def feminize content
  tree = Nokogiri::HTML content
  feminize_node! tree
  content = tree.to_html
  content = add_custom_logo content
  content
end

def feminize_node! node, indent = 0
  node.children.each do |child|
    if 'text' == child.name
      # print " "*indent
      # puts "feminizing: #{child.inspect}"
      child.content = feminize_text(child.content)
    elsif 'a' == child.name
      # puts "rewriting: #{child.attributes['href'].value}"
      child.attributes['href'].value =
      child.attributes['href'].value.
            sub(/https?:\/\/artofmanliness.com\/?/, '/')
    elsif child.children.size > 0
      # print " "*indent
      # puts "-> #{child.name}"
      feminize_node! child, indent + 1
    end
  end
end

def feminize_text string
  return string if string.blank?

  string = string.dup.without_accents
  ok = "([\s':;\.,\>\<\?\!])"

  {
    'manly' =>      'womanly',
    'manliness' =>  'womanliness',
    'man' =>        'woman',
    'men' =>        'women',
    'masculine' =>  'feminine',
    'male' =>       'female',
    'boy' =>        'girl',
    'his' =>        'her',
    'he' =>         'she'
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




