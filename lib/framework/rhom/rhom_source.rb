#------------------------------------------------------------------------
# (The MIT License)
# 
# Copyright (c) 2008-2011 Rhomobile, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# http://rhomobile.com
#------------------------------------------------------------------------

#require 'time'
require 'rhom/rhom_object'

module Rhom
  class RhomSource
    include ::Rhom::RhomObject
    attr_reader   :source_id, :name, :last_updated, :last_inserted_size, 
                  :last_deleted_size, :last_sync_duration,
                  :last_sync_success, :distinct_objects, :backend_refresh_time,
                  :partition, :schema, :schema_version
                  
    def initialize(args,count=0)
      # setup the name
      # TODO: should really store this in the database
      #Rho::RhoConfig::sources.each do |key,value|
      #  if value['source_id'].to_i == args['source_id'].to_i
      #    @name = key
      #  end
      #end
      @name = args['name']
      @source_id = args['source_id'].to_i
      @last_updated = Time.at(args['last_updated'].to_i)
      @last_inserted_size = args['last_inserted_size'].to_i
      @last_deleted_size = args['last_deleted_size'].to_i
      @last_sync_duration = args['last_sync_duration'].to_i
      @last_sync_success = args['last_sync_success'].to_i == 1 ? true : false
      @backend_refresh_time = Time.at(args['backend_refresh_time'].to_i)
      @partition =  args['partition']
      @schema =  args['schema']
      @schema_version =  args['schema_version']
      
      #VERY SLOW OPERATION!
      #@distinct_objects = ::Rhom::RhomDbAdapter::select_from_table(
      #                                                      'object_values',
      #                                                       'object',
      #                                                       {"source_id"=>@source_id},
      #                                                       {"distinct"=>true}).length
    end
    
    def distinct_objects
        ::Rho::RHO.get_src_db(@name).select_from_table(
            'object_values',
            'object',
            {"source_id"=>@source_id},
            {"distinct"=>true}).length
    end    

    def get_lastsync_objectcount
        if defined?(RHOCONNECT_CLIENT_PRESENT)
            Rho::RhoConnectClient.get_lastsync_objectcount(@source_id.to_i)
        end
    end    
    
    class << self
      include ::Rhom::RhomObject
      
      def load_all_sources
        Rho::RHO.load_all_sources()
      end
       
      def find(*args)
        if args.first == :all || args.first == :first
          list = []
        
          ::Rho::RHO.get_db_partitions.each_value do |db|
              results = db.select_from_table('sources', '*')

              results.each do |result|
                list << RhomSource.new(result)
              end
          end
          
          
          if args.first == :first
            return list.length > 0 ? list[0] : nil
          end 
        
          list
          
        else 
        
          ::Rho::RHO.get_db_partitions.each_value do |db|
              result = ::Rho::RHO.get_src_db().select_from_table('sources', '*', 
                                                                {"name" => args.first})
              next unless result && result.length() > 0 
              
              return RhomSource.new(result.first)
          end    
          
          return nil
        end
        
      end
      
      def find_all_ashash
        ar = find(:all)  
        res = {}
        ar.each do |src|
            res[src.name] = src
        end
        
        res
      end
      
      #def update_attributes(params=nil)
      #  if params
      #    ::Rhom::RhomDbAdapter::update_into_table('sources', {"source_url"=>params['source_url']},
      #                                             {"source_id"=>strip_braces(params['source_id'])})
      #  end
      #end
    end
  end
end
