module BrInscricaoEstadual
	class RN9 < Common
		protected
			STATE_CODE = "20"
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
