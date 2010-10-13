# coding: utf-8

# taken from http://newsgroups.derkeiler.com/Archive/Comp/comp.lang.ruby/2009-04/msg01041.html

module StringWithoutAccents
  def without_accents
    string = ActiveSupport::Multibyte::Chars.tidy_bytes(self)

    {
      %w{  á à â ä ã  } => 'a',
      %w{  Ã Ä Â À Á  } => 'A',
      %w{  é è ê ë    } => 'e',
      %w{  Ë É È Ê    } => 'E',
      %w{  í ì î ï    } => 'i',
      %w{  Í Î Ì Ï    } => 'I',
      %w{  ó ò ô ö õ  } => 'o',
      %w{  Õ Ö Ô Ò Ó  } => 'O',
      %w{  ú ù û ü    } => 'u',
      %w{  Ú Û Ù Ü    } => 'U',
      %w{  ç          } => 'c',
      %w{  Ç          } => 'C',
      %w{  ñ          } => 'n',
      %w{  Ñ          } => 'N',
      %w{  ’          } => "'",
      %w{   �         } => ''

    }.each do |accents, normal|
      accents.each do |accent|
        string.gsub! accent, normal
      end
    end

    string

  end
end

String.send :include, StringWithoutAccents unless String.included_modules.include?(StringWithoutAccents)