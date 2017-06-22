module BrInscricaoEstadual
	class RR < Common
    protected
      STATE_CODE = "24"
      DIGITS_ZERO = [0]
      PESO = [1, 2, 3, 4, 5, 6, 7, 8]

      def calculate_verify(peso)
        result = calculate(peso)%9
		    digit_verify_inscription(result)      
      end

	end
end