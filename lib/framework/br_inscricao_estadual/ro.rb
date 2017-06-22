module BrInscricaoEstadual
  class RO < Common
  	def initialize(insc_est)
      self.insc_est = insc_est.gsub(/\D*/,'')
      convert_to_new_format if self.insc_est.size == 9
    end

    protected
      PESO = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      STATE_INSC_SIZE = 14
      DIGITS_ZERO = [10]

      def convert_to_new_format
      	self.insc_est = "00000000" + self.insc_est[3..-1]
      end

      def calculate_verify(peso)
      	result = (11 - calculate(peso)%11)
      	result -= 10 if result > 10 
				digit_verify_inscription(result)      
    	end
      
  end
end
