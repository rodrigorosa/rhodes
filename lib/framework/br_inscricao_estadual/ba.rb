module BrInscricaoEstadual
  class BA < Common
    def valid?
    	return (self.insc_est.size == 8) ? BA8.new(insc_est).valid? : BA9.new(insc_est).valid?
    end
  end

  module BACommon
  	def calculate_verify(peso)
			num_mod = (self.insc_est.start_with?('6','7','9') ? 11 : 10)
    	result = (num_mod - calculate(peso)%num_mod)
			digit_verify_inscription(result)      
    end

  end
end
