require 'neography'
require 'net/http'
require 'uri'
require 'json'

class Game
    attr_accessor :node_id, :game_id, :name, :price
    def initialize( props )
        puts "initializing"
        if !$neo
            $neo = Neography::Rest.new
            $neo.set_node_auto_index_status( true )
            $neo.add_node_auto_index_property( 'game_id' )
        end
        if props
            self.set_props( props )
        end
    end

    def set_props( props )
        puts "setting props"
        self.game_id = props[:game_id] || self.game_id
        self.node_id = props[:node_id] || self.node_id
        self.name = props[:name] || self.name
        self.price = props[:price] || self.price
    end

    def reset
        puts "reset game"
        self.game_id = nil
        self.node_id = nil
        self.name = nil
        self.price = nil
        @node = nil
    end

    def game_id
        @game_id.to_i
    end

    def node_id
        @node_id.to_i
    end


    def price
        @node_id || 0.0
    end

    def load
        puts "loading node from index"
        res = $neo.get_node_auto_index( 'game_id', self.game_id )
        @node  = res ? self.index_result2node( res.first ) : nil
    end

    def index_result2node( result )
        node_ids = result.to_s.scan(/node\/([0-9]+)\/relat/).flatten
        node_id = node_ids.length > 0 ? node_ids.first : nil
        
        puts "node id found: #{node_id.to_i}"

        @node = $neo.get_node( node_id.to_i )

        puts "get node's node"
        p @node

        @node
    end

    def inspect
        puts "inspecting..."
        puts "Game => {node_id: #{self.node_id}, game_id: #{self.game_id}, name: #{@name}, price: #{@price}}"
    end

    def node
        puts "returning node"
        @node
    end

    def save
        puts "saving game"
        self.load
        if !@node
            @node = $neo.create_node( :game_id => self.game_id, :name => self.name, :price => self.price )
            puts "Checking create return val"
            p @node
        else
            puts "Checking set_prop node val"
            p @node
            puts "Checking set_prop node val done"
            
            $neo.set_node_properties(@node, { :game_id => self.game_id, :name => self.name, :price => self.price })
        end
    end

    def delete
        puts "attempting to delete node"
        if @node
            $neo.delete_node( @node )
        end
    end
end

(1..10).each do |id|
    game = Game.new( :game_id => id, :name => "Cool Game #{id}" )
    game.save
end
