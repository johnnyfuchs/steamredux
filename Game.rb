require 'neography'
require 'net/http'
require 'uri'
require 'json'
require_relative 'NeoNode'

class Game
    attr_accessor :node_id, :game_id, :name, :price
    def initialize( props = false )
        if !$neo
            $neo = Neography::Rest.new
            $neo.set_node_auto_index_status( true )
            $neo.add_node_auto_index_property( @type )
        end
        if props
            self.set_props( props )
        end
    end

    def set_props( props )
        puts "setting props"
        @game_id = props[:game_id].to_i || @game_id
        @node_id = props[:node_id].to_i || @node_id
        @name    = props[:name]         || @name
        @price   = props[:price]        || @price
    end

    def node_id=( value )
        puts "setting node_id"
        @node_id = value.to_i
    end

    def load
        puts "loading node from index"
        res = $neo.get_node_auto_index( 'game_id', @game_id.to_i )
        if res
            @node_id = self.index_result2node( res.first )
        end
    end

    def index_result2node( result )
        #puts "looking for node_id in #{result.to_s}"
        node_ids = result.to_s.scan(/node\/([0-9]+)\/relat/).flatten
        id = node_ids.length > 0 ? node_ids.first.to_i : nil
        id
    end

    def inspect
        puts "Game => {node_id: #{@node_id}, game_id: #{@game_id}, name: #{@name}, price: #{@price}}"
    end

    def save
        puts "saving game"
        self.load
        if !@node_id || @node_id == 0
            puts "creating node"
            node = $neo.create_node( :game_id => @game_id.to_i, :name => @name, :price => @price )
            @node_id = self.index_result2node( node )
        else
            puts "setting props"
            $neo.set_node_properties(@node_id, { :game_id => @game_id, :name => @name, :price => @price })
        end
    end

end

(1..4).each do |id|
    game = Game.new( :game_id => id, :name => "Cool Game #{id}", :price => "just#{id}")
    game.save
end
