require 'open-uri'
require 'nokogiri'
require 'cgi'

class SteamGameStrape
    def initialize
        @page = 1
        @url = "http://store.steampowered.com/search/results"
        @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22"
        @row = 0
        @doc
        @ele
    end

    # Incremnts the page count.
    # Loads the network request results into a Nokogiri HTML document.
    # Returns the array of formated and filtered results.
    def next_page
        @page = @page.next
        doc_content = open("#{@url}?page=#{@page}", "User-Agent" => @user_agent)
        @doc = Nokogiri::HTML( doc_content )
        page_results = self.parse_page
        page_results
    end

    # Finds all the blocks that match .search_result_row using a css selector.
    # Sets the @ele reference to the next result.
    # All parsing will be done on this object.
    def parse_page
        rows = @doc.css('.search_result_row')
        results = []
        rows.each do |ele|
            @row = @row.next
            @ele = ele
            id = self.game_id
            if id
                results << self.format_next_row( id, self.game_price, self.game_name, self.game_type )
            end
        end
        results
    end

    # Just joins all the arguments with tabs.
    # This is where some db updating could happen.
    def format_next_row( id, price, name, type)
        "#{@row.to_s}\t#{id}\t#{type}\t#{price}\t#{name}"
    end

    # Parse out the content type, ie: game, downloadable content, video preview, etc.
    def game_type
        img_ele = @ele.css('.search_type img')
        if img_ele && img_ele.length && img_ele.first.attribute('src')
            type = img_ele.first.attribute('src').content.scan(/(app|dlc|vid|mod|guide)/).first.first
        else
            type = '???'
        end
        type
    end

    # Parse out the Steam game reference id from the link to the detail page.
    def game_id
        app = @ele.attribute('href').content.scan(/app\/[0-9]+/)
        id = app.first ? app.first.gsub(/app\//,'') : nil
        id
    end
    
    # Get the game name.
    def game_name
        raw_name = @ele.css('.search_name h4').first
        # Killing special characters, Encoding::ISO_8859_1 was a pain to convert to UTF-8 versions.
        raw_name ? raw_name.content.gsub(/[\s]+/, " ").gsub(/[^a-zA-Z0-9 :\-\&\.,]/, '') : ''
    end
    
    # Parse out the game price... for some reason.
    def game_price
        raw_price = @ele.css('.search_price').first.content.split('$').last
        raw_price ? raw_price : 'Free to Play'
    end
end


#
# Executing script (main)
#
ss = SteamGameStrape.new

# As long as results come back, keep fetching new pages.
while res = ss.next_page do
    res.each do |row|
        puts row
    end
    
    # Stall execution for five seconds to be nice to Steam servers.
    sleep( 5 )
end

