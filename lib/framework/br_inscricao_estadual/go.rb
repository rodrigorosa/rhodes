module BrInscricaoEstadual
  class GO < Common
    protected
      STATE_CODE = ["10", "11", "15"]
      DIGITS_ZERO = [0]
      
      def digit_verify_inscription(result)
        if insc_int_arr.take(PESO.size).join().to_i == 11094402 then
          return insc_int_arr.last if [1,0].include?(insc_int_arr.last)
        end

        verify_result(result)
      end

      def calculate_verify(peso)
        result = calculate(peso)%11
        digit_verify_inscription(result)      
      end

      def insc_int_arr
        self.insc_est.split('').collect(&:to_i)
      end

      def insc_int_arr_take
         insc_int_arr.take(PESO.size).join().to_i
      end

      def verify_result(result)
        if self.class::DIGITS_ZERO.include?(result)
          0 
        elsif result == 1
          (insc_int_arr_take >= 10103105 && insc_int_arr_take <= 10119997) ? 1 : 0 
        else
          (11 - result%11)
        end
      end
  end
end
