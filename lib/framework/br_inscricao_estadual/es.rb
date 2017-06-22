module BrInscricaoEstadual
  class ES < Common
    protected
      DIGITS_ZERO = [0,1]

    def calculate_verify(peso)
    	result = (calculate(peso)%11)
			digit_verify_inscription(result)      
    end
      
  end
end
