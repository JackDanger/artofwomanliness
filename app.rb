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
  FileUtils.mkdir_p(directory)

  location = File.join(directory, filename)

  # serve from cache
  return File.read(location) if File.exist?(location)


  content = feminize retrieve(path)
  content = tag_with_analytics content

  File.open(location, 'w') do |f|
    f.write content # write to cache
  end
  content
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
  case node.name
  when 'text'
    # print " "*indent
    # puts "feminizing: #{child.inspect}"
    node.content = feminize_text(node.content)
  when 'a'
    # puts "rewriting: #{child.attributes['href'].value}"
    if href = node.attributes['href']
      href.value = href.value.sub(/https?:\/\/artofmanliness.com\/?/, '/')
    end
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
  return string if string.blank?

  string = string.dup.without_accents
  ok = %Q{([\s"':;\.,\>\<\?\!])}

  {
    'manly' =>      'womanly',
    'manliness' =>  'womanliness',
    'man' =>        'woman',
    'men' =>        'women',
    'masculine' =>  'feminine',
    'male' =>       'female',
    'boy' =>        'girl',
    'guy' =>        'girl',
    'dude' =>       'lady',
    'he' =>         'she',
    'his' =>        'her',
    'him' =>        'her',
    'himself' =>    'herself',
    'nobleman' =>   'noblewoman',
    'king' =>       'queen',
    'sissy' =>      'boyish',
    'cowboy' =>     'cowgirl',
    'dad' =>        'mom',
    'daddy' =>      'mommy',
    'dick' =>       'pussy',
    'ex-wife' =>    'ex-husband',
    'father' =>     'mother',
    'fathers' =>    'mothers',
    'brother' =>    'sister',
    'brothers' =>   'sisters'
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

def tag_with_analytics html
  html + ANALYTICS
end
ANALYTICS = %q{
<script type="text/javascript">
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-331450-15']);
_gaq.push(['_trackPageview']);
(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();
</script>}