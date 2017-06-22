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

require 'date/format'

class Time

  def getlocal() localtime end
  def to_time() getlocal end

  def __makeTwoDigit(num)
    str = num.to_s
    if str.length < 2
        str = '0' + str
    end
    
    str    
  end
  
  def __getPM()
    strPM = 'AM'
    nHour = hour();
    if nHour >= 12
        strPM = 'PM'
        nHour = nHour-12 if nHour > 12
    end

	return strPM, nHour
  end

  def strftime(fmt='%F')
    if fmt == "%m/%d/%Y, %I:%M%p"
        strRes = "" 
        strPM, nHour = __getPM()

        strRes += __makeTwoDigit(mon()) + '/' + __makeTwoDigit(mday()) + '/' + year().to_s + ', ' + __makeTwoDigit(nHour) + ':' + __makeTwoDigit(min()) + strPM;
        return strRes 
    elsif fmt == "%Y%m%dT%H%M%S.000 GMT"
        strRes = year().to_s() +  __makeTwoDigit(mon()) + __makeTwoDigit(mday()) + "T" + __makeTwoDigit(hour()) + __makeTwoDigit(min()) + __makeTwoDigit(sec()) +
            ".000 GMT"
        
        return strRes
	elsif fmt == '%a %b %d %Y'		 
        strRes = LocalizationSimplified::DateHelper::AbbrDaynames[wday()] + ' ' + LocalizationSimplified::DateHelper::AbbrMonthnames[mon()] + ' ' + __makeTwoDigit(mday()) + ' ' + year().to_s()
		return strRes 
	elsif fmt == '%d %Y'		 
        strRes = "Test"
		return strRes 
    elsif fmt == '%Y%m%d'
        strRes = year().to_s() +  __makeTwoDigit(mon()) + __makeTwoDigit(mday())
		return strRes 
    elsif fmt == '%m/%d/%Y'
        strRes = __makeTwoDigit(mon()) + "/" + __makeTwoDigit(mday()) + "/" + year().to_s()
		return strRes 
    elsif fmt == '%I:%M%p'
        strPM, nHour = __getPM()
        strRes += __makeTwoDigit(nHour) + ':' + __makeTwoDigit(min()) + strPM;
		return strRes 
    elsif fmt == '%a'
		strRes = LocalizationSimplified::DateHelper::AbbrDaynames[wday()]
		return strRes 
    elsif fmt == '%b'
		strRes = LocalizationSimplified::DateHelper::AbbrMonthnames[mon()]
		return strRes 
    elsif fmt == '%d'
		strRes = __makeTwoDigit(mday())
		return strRes 
    elsif fmt == '%Y'
		strRes = year().to_s()
		return strRes 
    elsif fmt == '%M'
		strRes =  __makeTwoDigit(min())
		return strRes 
    elsif fmt == '%H'
		strRes =  __makeTwoDigit(hour())
		return strRes 
    elsif fmt == '%p'
        strPM, nHour = __getPM()
		strRes =  strPM
		return strRes 

    end

	#puts "strftime: " + fmt

    DateTime.new(self).strftime(fmt)
  end

end

class Date

  SECONDS_IN_DAY         = Rational(1, 86400) # :nodoc:

  def self.today
    Date.new( Time.now )
  end

  def self.strptime(str='-4712-01-01', fmt='%F')
    Date.new( Time.strptime(str,fmt) )
  end

  def to_s() 
	format('%.4d-%02d-%02d', year(), mon(), mday()) 
  end # 4p
  
  def self.civil(y=-4712, m=1, d=1, sg=2299161)
    Date.new( Time.new(y,m,d) )
  end
  
  def _get_date
    @m_date      
  end
  
  def - (x)
    case x
    when Numeric; return Date.new( @m_date - x*(60*60*24) )
    when Date;    return ((@m_date-x._get_date()).to_i)/(60*60*24)
    end
    raise TypeError, 'expected numeric or date'
    
  end

  def + (x)
    case x
    when Numeric; return Date.new( @m_date + x*(60*60*24) )
    end
    raise TypeError, 'expected numeric'
    
  end

  # Get the week day of this date.  Sunday is day-of-week 0;
  # Saturday is day-of-week 6.
  def wday() @m_date.wday end
  
  # Get the commercial day of the week of this date.  Monday is
  # commercial day-of-week 1; Sunday is commercial day-of-week 7.
  def cwday() 
    _wday = @m_date.wday
    return 7 if _wday == 0
    
    return _wday
  end

  # Get the commercial week of the year of this date.
  # TODO: cweek()
  #def cweek() 0 end
  
  def mon() @m_date.mon end
  def year() @m_date.year end
  def mday() @m_date.mday end
  def day() @m_date.day end  
  def offset() 
    of = Rational(@m_date.gmt_offset() || 0, 86400)
  end
  def hour() @m_date.hour end
  def min() @m_date.min end
  def sec() @m_date.sec end
  
  def initialize( time )
    @m_date = time
  end
  
  def self.now()
    Date.new( Time.now )  
  end

  private_class_method :now

  def to_time() Time.local(year(), mon(), mday()) end
  def to_date() self end
  
end

class DateTime < Date

  def wday() @m_time.wday end
  def mon() @m_time.mon end
  def year() @m_time.year end
  def mday() @m_time.mday end
  def hour() @m_time.hour end
  def min() @m_time.min end
  def sec() @m_time.sec end
  def offset() 
    of = Rational(@m_time.gmt_offset() || 0, 86400)
  end
  
  def initialize( time )
    @m_time = time
  end

  def to_datetime() self end

  private_class_method :today
  public_class_method  :now  
end
