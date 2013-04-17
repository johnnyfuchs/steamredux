require 'open-uri'
require 'nokogiri'
require 'cgi'

class UserSeeder
    def initialize
        @forum = 0

        @user_buffer = []
        @topic_buffer = []

        @forum_page = 0
        @forum_pages = 0
        @forum_page_size = 50
        @forum_contents = ""

        #@topics_url = "http://steamcommunity.com/forum/4009259/General/render/0/?start=15&count=15"
        @forum_url = "http://steamcommunity.com/forum/4009259/General/render"
        @discussion_url = "http://steamcommunity.com/discussions/forum/"
        @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.172 Safari/537.22"
    end

    def next_forum( attempts = 10 )
        puts "checking next forum number #{@forum} with #{attempts} remaining...\n"
        unless attempts
            abort("cannot find a new forum")
        end
        forum_content = open("#{@forum_url}/#{@forum}/?start=0&count=#{@forum_page_size}", "User-Agent" => @user_agent)
        sleep(2)
        @forum_contents = forum_content.read
        @forum_pages = self.get_forum_page_count
        if @forum_pages > 0
            @forum_page = 0
        else
            @forum = @forum.next
            attempts -= 1
            self.next_forum( attempts )
        end
    end

    def fill_topic_buffer
        puts "filling topic buffer using page #{@forum_page} of #{@forum_pages}\n"
        if @forum_page < @forum_pages
            start = @forum_page * @forum_page_size
            forum_content = open("#{@forum_url}/#{@forum}/?start=#{start}&count=#{@forum_page_size}", "User-Agent" => @user_agent)
            sleep(2)
            @forum_contents = forum_content.read
            page_topics = @forum_contents.scan(/steamcommunity.com\\\/discussions\\\/forum\\\/[0-9]+\\\/([0-9]+)\\\//).flatten
            if page_topics.length > 0
                @topic_buffer.concat( page_topics )
            else
                @forum_page = @forum_page.next
                self.fill_topic_buffer
            end
        else
            self.next_forum
            self.fill_topic_buffer
        end
    end

    def get_user
        puts "getting user\n"
        if @user_buffer.length > 0
            return @user_buffer.shift
        else
            self.fill_user_buffer
            return self.get_user
        end
    end

    def fill_user_buffer
        puts "filling user buffer\n"
        # check the discussion topic buffer
        if @topic_buffer.length > 0
            self.users_from_topic( @forum, @topic_buffer.shift )
        else
            self.fill_topic_buffer
            self.users_from_topic( @forum, @topic_buffer.shift )
        end
    end

    def users_from_topic( forum, topic )
        puts "getting users from forum #{forum} and topic #{topic}\n"
        content = open("#{@discussion_url}/#{forum}/#{topic}/", "User-Agent" => @user_agent)
        sleep(2)
        doc = Nokogiri::HTML( content )
        doc.css('.commentthread_author_link, .forum_op_author').each do |link|
            @user_buffer << link.attribute('href').content.split('/').last
        end
    end

    def get_forum_page_count
        puts "getting page count\n"
        pages = 0
        if @forum_contents.length > 10
            if match = @forum_contents.match(/"total_count"\s?:\s?(null|[0-9]+)/i)
                count, null = match.captures
                pages = count.to_i / @forum_page_size.to_f
                pages = pages.ceil
            end
        end
        return pages
    end
end


#
# Executing script (main)
#
di = UserSeeder.new

while true
    u = di.get_user
    puts "********user: #{u}\n"
end

