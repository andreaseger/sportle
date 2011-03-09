module Sinatra
  module MyHelper
    def pluralize(number, text)
      return text.pluralize if number != 1
      text
    end
    
    include Rack::Utils
    alias_method :h, :escape_html
    
    def section(key, *args, &block)
      @sections ||= Hash.new{ |k,v| k[v] = [] }
      if block_given?
        @sections[key] << block
      else
        @sections[key].inject(''){ |content, block| content << block.call(*args) } if @sections.keys.include?(key)
      end
    end
    
    def title(page_title, show_title = true)
      section(:title) { page_title.to_s }
      @show_title = show_title
    end

    def show_title?
      @show_title
    end
    
    def tag_cloud(classes)
      tags = Schedule.get_tags
      return if tags.empty?
      max_count = tags.sort_by{|t| t[1] }.last[1]

      tags.each do |tag|
        index = ((tag[1].to_f / max_count) * (classes.size - 1)).round
        yield tag[0], classes[index]
      end
    end
    
    def cache_page(seconds=5*60)
      response['Cache-Control'] = "public, max-age=#{seconds}" unless Sinatra::Base.development?
    end
    
    def button_to(name, path, method='post')
      haml <<END
%form{:method => '#{method}', :action => '#{path}'}
  %input{:value => '#{name}', :type => 'submit'}
END
    end

    def auth?
      true
    end
  end
end
