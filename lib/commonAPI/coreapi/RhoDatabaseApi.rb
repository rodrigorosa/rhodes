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

module Rho
class Database

  @database = nil
  @dbpath = nil

#-----------------------------------------
#public API
  # maintains a single database connection
  def initialize(dbfile, partition)
    unless @database
      @dbpath = dbfile
      @database = SQLite3.new(dbfile,partition)
    end
  end

  # closes the database if and only if it is open
  def close
    if @database
      @database.close
      @database = nil
      @dbpath = nil
    else
      return false
    end
    return true
  end


  def isUiWaitForDb
      @database.isUiWaitForDb
  end
  alias is_ui_waitfordb :isUiWaitForDb

  def startTransaction
      begin
        @database.startTransaction
      rescue Exception => e
        puts "exception when startTransaction: #{e}"
        raise
      end
  end
  alias start_transaction :startTransaction

  def commitTransaction
      begin
        @database.commitTransaction
      rescue Exception => e
        puts "exception when commit transaction : #{e}"
        raise
      end
  end
  alias commit :commitTransaction

  def rollbackTransaction
      begin
        @database.rollbackTransaction
      rescue Exception => e
        puts "exception when rollback transaction : #{e}"
        raise
      end
  end
  alias rollback :rollbackTransaction

  def lockDb
      begin
        @database.lockDb
      rescue Exception => e
        puts "exception when lockDb: #{e}"
        raise
      end
  end
  alias lock_db :lockDb

  def unlockDb
      begin
        @database.unlockDb
      rescue Exception => e
        puts "exception when unlockDb: #{e}"
        raise
      end
  end
  alias unlock_db :unlockDb

  def export
	  begin
		@database.export
	  rescue Exception => e
		puts "exception when export database: #{e}"
		raise
      end
  end

  def import(zipName)
	  begin
		@database.import(zipName)
	  rescue Exception => e
		puts "exception when import database: #{e}"
		raise
	  end
  end

  # execute a sql statement
  # optionally, disable the factory processing
  # which returns the result array directly
  def executeSql(sql, *args)
    _execute_sql(sql, false, args)
  end
  def executeBatchSql(sql, *args)
    _execute_sql(sql, true, args)
  end
  alias execute_sql :executeSql
  alias execute_batch_sql :executeBatchSql

  def setDoNotBackupAttribute( attr = true )
    if Rho::System.platform == Rho::System.PLATFORM_IOS
        Rho::System.setDoNotBackupAttribute(@dbpath, attr)
        Rho::System.setDoNotBackupAttribute(@dbpath+'.version', attr)
    end
  end
  alias set_do_not_bakup_attribute :setDoNotBackupAttribute

  def isTableExist(table_name)
    @database.isTableExist(table_name)
  end
  alias table_exist? :isTableExist

  #destroy one table
  def destroyTable(name)
    destroyTables(:include => [name])
  end
  alias destroy_table :destroyTable

  # deletes all rows from all tables, except list of given tables by recreating db-file and save all other tables
  # arguments - :include, :exclude
  def destroyTables(*args)
      @database.destroyTables args.first[:include], args.first[:exclude]
  end
  alias destroy_tables :destroyTables

#----------------------------------------
#internal API
  def _execute_sql(sql, is_batch, args)
    result = []
    if sql
      #puts "RhomDbAdapter: Executing query - #{sql}; #{args}"
      begin
        result = @database.execute( sql, is_batch, args )
        #puts "result : #{result}"
      rescue Exception => e
        puts "exception when running query: #{e}"
        puts "query: #{sql}"
        raise
      end
    end
    result
  end

  class << self

      def safe_str_escape(value)
        str = str.kind_of?(String) ? value.strip : value.to_s
        # escape string if it not starts and ends with single or double quotes
        is_esacped = 
          (str.start_with?('\'') && str.end_with?('\'')) ||
          (str.start_with?('\"') && str.end_with?('\"')) 
        str = (is_esacped ? str : "'#{str}'")
        # replace quotes in the middle of string
        str.gsub(/(?<!^)'(?!$)/,"''")
      end

      # generates where clause based on hash
      def where_str(condition)
        where_str = ""
        if condition
          where_str += string_from_key_vals(condition,"and")
          where_str = where_str[0..where_str.length - 5]
        end

        where_str
      end

      def select_str(select_arr)
        select_str = ""
        select_arr.each do |attrib|
          select_str << safe_str_escape(attrib) + ","
        end
        select_str.length > 2 ? select_str[0..select_str.length-2] : select_str
      end

      # generates value clause based on hash
      def vals_str(values)
        vals = string_from_key_vals_set(values, ",")
        vals[0..vals.length - 2]
      end

      def string_from_key_vals_set(values, delim)
        vals = ""
        values.each do |key,value|
          op = '= '
          vals << " \"#{key}\" #{op} #{get_value_for_sql_stmt(value)} #{delim}"
        end
        vals
      end

      # generates key/value list
      def string_from_key_vals(values, delim)
        vals = ""
        values.each do |key,value|
          op = value.nil? ? 'is ' : '= '
          vals << " \"#{key}\" #{op} #{get_value_for_sql_stmt(value)} #{delim}"
        end
        vals
      end

      # generates a value for sql statement
      def get_value_for_sql_stmt(value, convert_value_to_string=true)
        if value.nil? or value == 'NULL'
          "NULL"
        elsif value.is_a?(String)
          safe_str_escape(value)
        else
          if convert_value_to_string
            safe_str_escape(value)
          else
            "#{value}"
          end
        end
      end

      def make_where_params(condition,op)
        raise ArgumentError if !condition || !op || op.length == 0
        quests = ""
        vals = []

        condition.each do |key,val|
            if quests.length > 0
                quests << ' ' << op << ' '
            end

            if val.nil?
                quests << "\"#{key}\" IS NULL"
            else
                quests << "\"#{key}\"=?"
				vals << val
            end

        end

        return quests,vals
      end

    end #self


  # support for select statements
  # this function takes table name, columns (as a comma-separated list),
  # condition (as a hash), and params (as a hash)
  # example usage is the following:
  # select_from_table('object_values', '*', {"source_id"=>2,"update_type"=>'query'},
  #                   {"order by"=>'object'})
  # this would return all columns where source_id = 2 and update_type = 'query' ordered
  # by the "object" column
  def select_from_table(table=nil,columns=nil,condition=nil,params=nil)

    raise ArgumentError if !table || !columns
    query = nil
    vals = []

    if condition
        quests,vals = Database.make_where_params(condition,'AND')
        if params and params['distinct']
            query = "SELECT DISTINCT #{columns} FROM \"#{table}\" WHERE #{quests}"
        elsif params and params['order by']
            query = "SELECT #{columns} FROM \"#{table}\" WHERE #{quests} ORDER BY #{params['order by']}"
        else
            query = "SELECT #{columns} FROM \"#{table}\" WHERE #{quests}"
        end
    else
        query = "SELECT #{columns} FROM \"#{table}\""
    end

    execute_sql query, vals
  end

  # inserts a single row into the database
  # takes the table name and values (hash) as arguments
  # exmaple usage is the following:
  # insert_into_table('object_values, {"source_id"=>1,"object"=>"some-object","update_type"=>'delete'})
  # this would execute the following sql:
  # insert into object_values (source_id,object,update_type) values (1,'some-object','delete');
  def insert_into_table(table=nil,values=nil, excludes=nil)
    raise ArgumentError if !table
    cols,quests,vals = make_insert_params(values, excludes)
    query = "INSERT INTO \"#{table}\" (#{cols}) VALUES (#{quests})"
    execute_sql query, vals
  end

  def make_insert_params(values, excludes)
    raise ArgumentError if !values

    cols = ""
    quests = ""
    vals = []

    values.each do |key,val|
        next if excludes && excludes[key]
        if cols.length > 0
            cols << ','
            quests << ','
        end

        cols << "\"#{key}\""
        quests << '?'
        vals << val
    end

    return cols,quests,vals
  end

  # deletes rows from a table which satisfy condition (hash)
  # example usage is the following:
  # delete_from_table('object_values',{"object"=>"some-object"})
  # this would execute the following sql:
  # delete from object_values where object="some-object"
  def delete_from_table(table,condition)
    raise ArgumentError if !table
    quests,vals = Database.make_where_params(condition,'AND')
    query = "DELETE FROM \"#{table}\" WHERE #{quests}"
    execute_sql query, vals
  end

  # deletes all rows from a given table
  def delete_all_from_table(table)
    execute_sql "DELETE FROM \"#{table}\""
  end

  def delete_table(table)
    execute_sql "DROP TABLE IF EXISTS \"#{table}\""
  end

  # updates values (hash) in a given table which satisfy condition (hash)
  # example usage is the following:
  # update_into_table('object_values',{"value"=>"Electronics"},{"object"=>"some-object", "attrib"=>"industry"})
  # this executes the following sql:
  # update table object_values set value='Electronics' where object='some-object' and attrib='industry';
  def update_into_table(table=nil,values=nil,condition=nil)
    raise ArgumentError if !table || !values
    query = nil
    vals = []
    if condition
        quests_set, vals_set = make_set_params(values)
        quests_where,vals_where = Database.make_where_params(condition,'AND')
        query = "UPDATE \"#{table}\" SET #{quests_set} WHERE #{quests_where}"
        vals = vals_set + vals_where
    else
        quests, vals = make_set_params(values)
        query = "UPDATE \"#{table}\" SET #{quests}"
    end

    execute_sql query, vals
  end

  def make_set_params(values)
    raise ArgumentError if !values

    quests = ""
    vals = []

    values.each do |key,val|
        if quests.length > 0
            quests << ','
        end

        quests << "\"#{key}\"=?"
        vals << val
    end

    return quests,vals
  end


end # Database
end # Rho


module Rhom
    RhomDbAdapter = Rho::Database
end

