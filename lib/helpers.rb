helpers do
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
  
  def all_tags
    @tags ||= Schedule.get_tags
  end
  
  def cache_page(seconds=5*60)
		response['Cache-Control'] = "public, max-age=#{seconds}" unless development?
	end
	
	def button_to(name, path, method='post')
	  haml <<END
%form{:method => '#{method}', :action => '#{path}'}
  %input{:value => '#{name}', :type => 'submit'}
END
	end
end
