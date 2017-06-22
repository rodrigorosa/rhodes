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

require 'bsearch'
require 'time'

module Rho
	module RhoEvent
    def self.find(*args)
      if args.first == :all
        params = {}
        if args.length >= 2 and args[1].is_a? Hash
          puts "Event find params: #{args[1].inspect}"
          args[1].each do |k,v|
            params[k.to_s] = v
            puts "#{k.to_s} => #{v}"
          end
        end

        params['start_date'] = params['start_date'].to_time if !params['start_date'].nil? and !params['start_date'].is_a?(Time)
        params['end_date'] = params['end_date'].to_time if !params['end_date'].nil? and !params['end_date'].is_a?(Time)
        
        params['start_date'] = MIN_TIME if params['start_date'].nil? #or params['start_date'] < MIN_TIME
        params['end_date'] = MAX_TIME if params['end_date'].nil? #or params['end_date'] > MAX_TIME
        
        if params['start_date'] == MIN_TIME or params['end_date'] == MAX_TIME
          params['include_repeating'] = false
          puts "Resetting 'include_repeating' param to false"
        end
        
        puts "Rho::Calendar.fetch(params) : #{params}"
        events = Rho::Calendar.fetch(params)
        #puts "events : #{events}"
        #ret = {}
        #events.each do |e|
        #  ret[e[Rho::RhoEvent::ID]] = e
        #end
        #ret
        events
      else
        id = args.first.to_s
        id = $1 if id.is_a?(String) and id =~ /^{(.*)}$/
        Rho::Calendar.fetch_by_id(id)
      end
    end

    def self.create!(event)
      event['id'] = nil #indicate that event should be created
      event['reminder'] = event['reminder'].to_i if event['reminder'] != nil
      event['recurrence']['end'] = nil if event['recurrence'] and event['recurrence']['end'] == ""
      new_id = Rho::Calendar.save(event)
      event['id'] = new_id
      return event
    end

    def self.destroy(id)
      id = $1 if id.is_a?(String) and id =~ /^{(.*)}$/
      Rho::Calendar.delete(id)
    end

    def self.update_attributes(event)
      puts "update_attributes: #{event}"
      Rho::Calendar.save(event)
    end

	end # module RhoEvent
end # module Rho
