require 'open-uri'
require 'nokogiri'

user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22"
url = "http://store.steampowered.com/search/results"
doc = Nokogiri::HTML(open(url, "User-Agent" => user_agent))
#puts open(url, "User-Agent" => user_agent).readlines

# Print out each link using a CSS selector
doc.css('.search_result_row').each do |link|
    puts link.content.gsub(/\s+/, " "), "\n"
end
