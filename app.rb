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
    if child.children.size > 0
      # print " "*indent
      # puts "-> #{child.name}"
      feminize_node! child, indent + 1
    elsif child.respond_to?(:content)
      # print " "*indent
      # puts "feminizing: #{child.name}"
      child.content = feminize_text!(child.content)
    end
  end
end

def feminize_text! string
  {
    %r{([^\w])Man$} =>      '\1Woman',
    %r{([^\w])man$} =>      '\1woman',
    %r{([^\w])Men$} =>      '\1Women',
    %r{([^\w])men$} =>      '\1women',
    %r{([^\w])Mascul$} =>   '\1Femin',
    %r{([^\w])mascul$} =>   '\1femin',
    %r{([^\w])Male$} =>     '\1Female',
    %r{([^\w])male$} =>     '\1female',
    %r{([^\w])Boy$} =>      '\1Girl',
    %r{([^\w])boy$} =>      '\1girl',
    %r{([^\w])His $} =>     '\1Her ',
    %r{([^\w])his $} =>     '\1her ',
    %r{([^\w])He $} =>      '\1She ',
    %r{([^\w])he $} =>      '\1she '
  }.each do |pattern, replace|
    string.gsub! pattern, replace
  end
  string
end
