require 'neography'
require 'net/http'
require 'uri'
require 'json'


class NeoNode
    attr_accessor :node_id
    
    # only really helpful thing is the "type" or index that the node
    # can be looked up by (game, player, etc)
    def initialize
        @node_id = nil
        if !$neo
            $neo = Neography::Rest.new
            $neo_indexes = $neo.list_indexes
        end
    end

    def index( prop )
        $neo.set_node_auto_index_status( false )
        $neo.create_node_index( prop, 'fulltext', 'lucene' )
        $neo_indexes = $neo.list_indexes
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

    def id
        @node_id
    end

    def relationships
        rels = []
        if @node_id && @node_id > 0
            begin
                result = $neo.get_node_relationships( @node_id )
                if result
                    result.each {|res| rels << ship_id_from_result( res )}
                end
            rescue
                puts "no relationships for #{@node_id}"
            end
        end
        rels
    end

    def unbind( other_node )
        all = relationships
        all.each do |other|
            if other[:node].to_i == other_node.to_i
                begin
                    res = $neo.delete_relationship( other[:rel] )
                rescue
                    puts "failed to unbind #{@node_id} #{other_node}"
                end
            end
        end
    end

    # loads a node based on the index or type
    def find( prop, id )
        begin
            res = $neo.find_node_index( prop, prop, id )
        rescue
            res = nil
        end
        if res
            @node_id = id_from_result( res.first )
        end
        @node_id
    end

    def bind( type, to, props )
        if to > 0 && type && @node_id && @node_id > 0
            begin
                $neo.create_relationship( type, @node_id, to, props )
                return true
            rescue
                puts "failed to bind #{@node_id} to #{to} with #{props}"
            end
        end
        return false
    end

    # creates or updates a node with the given map of properties
    def save( props )
        indexed = props.keys & $neo_indexes.keys.map {|x| x.to_sym }
        if indexed.length
            find( indexed.first, props[indexed.first] )
        end
        if !@node_id || @node_id == 0
            node = $neo.create_node( props )
            @node_id = id_from_result( node )
        else
            $neo.set_node_properties(@node_id, props )
        end

        indexed.each do |key|
            prop = props[key]
            $neo.remove_node_from_index( key, key, @node_id )
            $neo.add_node_to_index( key, key, prop, @node_id )
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

    def ship_id_from_result( result )
        ship = result['self'].scan(/lationship\/([0-9]+)/).flatten.first.to_i
        last = result['end'].scan(/node\/([0-9]+)/).flatten.first.to_i
        {:rel => ship, :node => last}
    end
end
