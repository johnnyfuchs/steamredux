require 'neography'
require 'net/http'
require 'uri'
require 'json'
require 'thread'
require_relative 'NeoNode'

n = NeoNode.new
n.index( :game )

queue = [] 
threads = []

found = 0
missed = 0

open('./games.txt').readlines.each { |item| queue << item }

20.times do
    threads << Thread.new do
        while queue.length > 0 do
            count, game_id, type, price, name = queue.pop.strip.split("\t") rescue nil
            n = NeoNode.new
            n.save( :game => game_id.to_i, :name => name, :price => price.to_f )
        end
    end
end

threads.each { |t| t.join }
