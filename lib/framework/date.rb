if defined? RHO_ME
	require 'dateME'
else
    require 'dateOrig'
end

#RHO
require 'rholang/localization_simplified'
# Modification of ruby constants
class Date
  alias_method :old_strftime, :strftime

  #FIXME as these are defined as Ruby constants, they can not be overwritten
  MONTHNAMES         = LocalizationSimplified::DateHelper::Monthnames
  ABBR_MONTHNAMES    = LocalizationSimplified::DateHelper::AbbrMonthnames
  DAYNAMES          = LocalizationSimplified::DateHelper::Daynames        #not in use by Rails
  ABBR_DAYNAMES     = LocalizationSimplified::DateHelper::AbbrDaynames    #not in use by Rails
  
  DATE_FORMATS	=	{ :short => "%e %b", :long => "%B %e, %Y", :db => "%Y-%m-%d", :number => "%Y%m%d" }
  #, :long_ordinal => lambda { |date| date.strftime("%B #{date.day.ordinalize}, %Y") }, # => "April 25th, 2007" :rfc822 => "%e %b %Y"
  DATE_FORMATS.merge!(LocalizationSimplified::DateHelper::DateFormats)

  def strftime(date)
  
    if LocalizationSimplified::get_cur_locale() == 'en'
        return old_strftime(date)
    end
    
    tmpdate=date.dup
    LocalizationSimplified::localize_strftime(tmpdate, self)
    old_strftime(tmpdate)
  end

  def to_formatted_s(type)
    strftime(DATE_FORMATS[type])
  end
end

