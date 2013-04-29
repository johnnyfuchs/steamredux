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
        @baseurl = "http://steamcommunity.com/"
        @gamepath = "/games/?tab=all"
        @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22"
        @gamer = false
    end

    # games method accepts valid Steam user name of profile id
    def games( gamer )
        @path = gamer.match(/[0-9]{17}/) ? "profiles/" : "id/"
        @gamer = gamer
        res = self.make_request
        res
    end

    # request fails if user is non-existent or invalid (yay no error checking!)
    # returns a tab formatted list of results
    def make_request
        doc_content = open("#{@baseurl}#{@path}#{@gamer}#{@gamepath}", "User-Agent" => @user_agent)
        @doc = Nokogiri::HTML( doc_content )
        res = self.reformat_games( self.get_json )
        res
    end

    # get_json performs the heavy lifting of this class
    # It searches the script tags for the javascript variable "rgGames",
    # which contains a json object of all the users' games.
    # This json string is parsed and reformatted for output to text file
    def get_json
        json = @doc.css('script')
        json.each do |script|
            body = script.content
            pos = body.index('var rgGames = ')
            if pos
                pos += 'var rgGames = '.length
                game_json, *others = body[pos, body.length].split(/;/)
                res = JSON.parse(game_json.strip)
                if res.kind_of?(Array) && res.first && res.first['appid'].to_i > 1
                    return res
                end
            end
        end
        return nil
    end


    # reformat_games - loops through json array input and pulls out
    # key data points for reformatted output
    def reformat_games( json )
        if !json
            return nil
        end
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
