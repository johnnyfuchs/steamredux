require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'json'

class UserGameScrape
    def initialize
        @baseurl = "http://steamcommunity.com/id/"
        @gamepath = "/games/?tab=all"
        @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22"
        @gamer = false
    end

    def games( gamer )
        @gamer = gamer
        doc_content = open("#{@baseurl}#{@gamer}#{@gamepath}", "User-Agent" => @user_agent)
        @doc = Nokogiri::HTML( doc_content )
        results = self.reformat_games( self.get_json )
        results
    end

    def get_json
        json = @doc.css('head script')
        json.each do |script|
            body = script.content
            pos = body.index('var rgGames = ')
            if pos
                pos += 'var rgGames = '.length
                game_json, *others = body[pos, body.length].split(/;/)
                return JSON.parse(game_json.strip).each
            end
        end
    end

    def reformat_games( json )
        formatted = []
        @row = 0
        json.each do |game|
            formatted << self.format_next_row( game['appid'], game['name'], game['hours_forever'] )
        end
        formatted
    end

    # Basically just joins arguments with tabs for later use.
    def format_next_row( id, name, hours )
        @row = @row.next
        name = name ? name.gsub(/[^a-zA-Z0-9 :\-\&\.,]/, '') : ''
        "#{@row.to_s}\t#{id}\t#{hours}\t#{name}\n"
    end
end


#
# Executing script (main)
#
ss = UserGameScrape.new

puts ss.games( "johnnyfuchs" )
