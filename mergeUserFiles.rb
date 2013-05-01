require 'neography'
require 'net/http'
require 'uri'

#puts "reading user list"
users = []
open('./unique_list_of_users.txt').readlines.each { |item| users << item.strip }

f = File.open('./all_user_games.txt', 'w')

#puts "running batches in chunks of #{chunk_size} users"
users.each do |player|
    file_path = "./user_games/#{player}.txt"
    if File.exists?( file_path )
        open( file_path ).readlines.each do |plays|
            count, game_id, play_time, name = plays.strip.split("\t") rescue nil
            f.puts "#{player}\t#{game_id}\t#{play_time}"
        end
    end
end
f.close
