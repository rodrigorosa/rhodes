module BrInscricaoEstadual
	class RN10 < Common
		protected
			PESO = [10, 9, 8, 7, 6, 5, 4, 3, 2]
			STATE_CODE = "20"
			STATE_INSC_SIZE = 10
			DIGITS_ZERO = [10]

		def calculate(peso)
			 super * 10 
		end

		def calculate_verify(peso)
      result = calculate(peso)%11
			digit_verify_inscription(result)      
    end
  end
end
