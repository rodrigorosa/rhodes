module BrInscricaoEstadual
	class SPP < Common
		protected
			PESO = [1, 3, 4, 5, 6, 7, 8, 10]
			STATE_INSC_SIZE = 12
			DIGITS_ZERO = [0,10]

		def calculate_verify(peso)
      result = (calculate(peso)%11)
      result -= 10 if result > 10 
			digit_verify_inscription(result)      
    end

  end
end
