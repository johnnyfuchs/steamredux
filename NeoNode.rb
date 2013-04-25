require 'neography'
require 'net/http'
require 'uri'
require 'json'


class NeoNode
    attr_accessor :node_id
    
    # only really helpful thing is the "type" or index that the node
    # can be looked up by (game, player, etc)
    def initialize( type )
        @type = type || 'name'
        @node_id = nil
        if !$neo
            $neo = Neography::Rest.new
            $neo.set_node_auto_index_status( true )
            $neo.add_node_auto_index_property( @type )
        end
    end

    # loads a node based on the id
    def load( id )
        begin
            res = $neo.get_node( id.to_i )
        rescue
            res = nil
        end
        if res
            @node_id = id.to_i
        end
    end

    # loads a node based on the index or type
    def find( id )
        begin
            res = $neo.get_node_auto_index( @type, id )
        rescue
            res = nil
        end
        if res
            @node_id = self.id_from_result( res.first )
        end
    end

    # creates or updates a node with the given map of properties
    def save( props )
        if !@node_id || @node_id == 0
            node = $neo.create_node( props )
            @node_id = self.id_from_result( node )
        else
            $neo.set_node_properties(@node_id, props )
        end
    end

    # deletes a node based on its id
    def delete
        unless !@node_id || @node_id == 0
            $neo.delete_node( @node_id )
        end
    end

    # pause, remove, and restart the database
    def reset_db
        puts "resetting database"
        path = "/Users/johnny.fuchs/code/neo4j-community-1.8.2/"
        stop = `#{path}bin/neo4j stop`
        p stop
        remove = `rm -rf #{path}data/graph.db`
        p remove
        start = `#{path}bin/neo4j start`
        p start
    end

    def id_from_result( result )
        node_ids = result.to_s.scan(/node\/([0-9]+)\/relat/).flatten
        id = node_ids.length > 0 ? node_ids.first.to_i : nil
        id
    end
end

#puts "test"
#puts "Initializes:"
n = NeoNode.new( 'game_id' )
n.find( 2 )
n.save( :game_id => 2, :name => "Cool Game 22", :price => "222222" )
p n

