require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'json'

# UserGameScrape
#
# Usage:
#  ugs = UserGameScrape.new
#  games_tsv_string = ugs.games( steam_game_name )
#  puts games_tsv_string
#
class UserGameScrape
    def initialize
        @baseurl = "http://steamcommunity.com/id/"
        @gamepath = "/games/?tab=all"
        @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22"
        @gamer = false
    end

    # games method accepts valid Steam user with public profile
    # open fails if user is non-existent or invalid (yay no error checking!)
    # returns a tab formatted list of results
    def games( gamer )
        @gamer = gamer
        doc_content = open("#{@baseurl}#{@gamer}#{@gamepath}", "User-Agent" => @user_agent)
        @doc = Nokogiri::HTML( doc_content )
        results = self.reformat_games( self.get_json )
        results
    end

    # get_json performs the heavy lifting of this class
    # It searches the script tags for the javascript variable "rgGames",
    # which contains a json object of all the users' games.
    # This json string is parsed and reformatted for output to text file
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


    # reformat_games - loops through json array input and pulls out
    # key data points for reformatted output
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
ugs = UserGameScrape.new

# printing out games to be dumped to file
puts ugs.games( "johnnyfuchs" )
