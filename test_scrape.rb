require 'open-uri'
require 'nokogiri'
require 'cgi'

class SteamStrape
    def initialize
        @page = 1
        @url = "http://store.steampowered.com/search/results"
        @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22"
        @row = 0
        @doc
        @ele
    end

    def next_page
        @page = @page.next
        doc_content = open("#{@url}?page=#{@page}", "User-Agent" => @user_agent)
        @doc = Nokogiri::HTML( doc_content )
        self.parse_page
    end

    def parse_page
        @doc.css('.search_result_row').each do |ele|
            @row = @row.next
            @ele = ele
            id = self.game_id
            if id
                self.format_next_row( id, self.game_price, self.game_name, self.game_type )
            end
        end
    end

    def format_next_row( id, price, name, type)
        puts "#{@row.to_s.ljust(5)} #{id.ljust(7)} #{type} #{price.ljust(15)} #{name.ljust(5)}"
    end

    def game_type
        @ele.css('.search_type img').first.attribute('src').content.scan(/(app|dlc|vid)/).first.first
    end

    def game_id
        app = @ele.attribute('href').content.scan(/app\/[0-9]+/)
        id = app.first ? app.first.gsub(/app\//,'') : nil
        id
    end
    
    def game_name
        opts = { :invalid => 'replace',
                 :undef => 'replace', 
                 :replace => '' }
        raw_name = @ele.css('.search_name h4').first
        raw_name ? raw_name.content.gsub(/[\s]+/, " ").encode( Encoding::ISO_8859_1 ).encode( Encoding::UTF_8, :invalid => :replace, :undef => :replace, :replace => "" ) : ''
    end
    
    def game_price
        raw_price = @ele.css('.search_price').first.content.split('$').last
        raw_price ? raw_price : 'Free to Play'
    end
end


ss = SteamStrape.new
ss.next_page
