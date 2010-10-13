## Resources
require 'rubygems' # sorry @defunkt, this is easier
gem 'sinatra', :version => '1.0'
require 'net/http'
require 'fileutils'
require 'nokogiri'
require 'sinatra'
require 'active_record'
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
  filename = 'index.html' if filename =~ /\/$/

  location = File.expand_path(File.join(TMPDIR, path))

  directory = location.chomp(filename).chomp('/')
  FileUtils.mkdir_p(directory)

  location = File.join(directory, filename)

  # return File.read(location) if File.exist?(location)


  content = retrieve path
  transform! path, content

  File.open(location, 'w') do |f|
    f.write content
  end
end

def transform! path, content
  case path
  when /(.jpg|.ico|.gif|.png)$/
    puts "passthrough: #{path}"
    content
  when /(.css|.txt|.js)$/
    puts "localize: #{path}"
    localize! content
    content
  else
    puts "feminize: #{path}"
    localize! content
    feminize! content
  end
end

def retrieve path
  Net::HTTP.get(URI.parse("http://artofmanliness.com#{path}"))
end

def localize! content
  content.gsub!("http://artofmanliness.com/", '/')
end

def feminize! content
  tree = Nokogiri::HTML content
  feminize_node! tree
  tree.to_html
end

def feminize_node! node, indent = 0
  node.children.each do |child|
    if 'text' == child.name
      # print " "*indent
      # puts "feminizing: #{child.inspect}"
      child.content = feminize_text!(child.content)
    elsif child.children.size > 0
      # print " "*indent
      # puts "-> #{child.name}"
      feminize_node! child, indent + 1
    end
  end
end

def feminize_text! string
  return string if string.blank?

  ok = "([\s':;\.,\>\<])"

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
