require 'neography'
require 'net/http'
require 'uri'
require_relative 'NeoNode'


n = NeoNode.new
n.reset_db
n.index(:game)

puts "reading game list"
games = []
open('./games.txt').readlines.each {|item| games << item }

# previously doing batches of games
# index was having trouble though
chunk_size = 40
game_groups = games.each_slice( chunk_size ).to_a

puts "total games: #{game_groups.flatten.count}"
puts "running batches in chunks of #{chunk_size} games"
batch = 0
game_groups.each do |games|
    game_i = 0
    ops = []
    game_names = []
    games.each do |line|
        game_id, name = line.strip.split("\t") rescue nil
        ops <<  [:create_node, {:game => game_id.to_i, :name => name}]
        ops <<  [:add_node_to_index, :game, :game, game_id.to_i, "{#{game_i}}"]
        game_i += 2
        game_names << name
    end
    puts "starting #{game_i} batch inserts, from #{game_names.first} to #{game_names.last}"
    $neo.batch( *ops )
    puts "completing batch inserts #{batch}"
    batch = batch.next
end
