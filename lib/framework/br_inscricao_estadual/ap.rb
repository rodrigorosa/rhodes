module BrInscricaoEstadual
	class AP < Common
    protected
      STATE_CODE = "03"
      DIGITS_ZERO = [10]

      def calculate(peso)
        calc = super
        calc + values_p_d[:p]
      end

      def digit_verify_inscription(result)
        if self.class::DIGITS_ZERO.include?(result)
           0 
        elsif result == 11 
          values_p_d[:d]
        else
          result
        end
      end

      def values_p_d
        @p_d ||= track_registry
      end

      def track_registry
        insc_est_arr = self.insc_est.split('').collect(&:to_i).take(PESO.size).join().to_i
        if insc_est_arr >= 3000001 && insc_est_arr <= 3017000 then
          {p: 5, d: 0}
        elsif insc_est_arr >= 3017001 && insc_est_arr <= 3019022 then
          {p: 9, d: 1}
        elsif insc_est_arr >= 3019023 then
          {p: 0, d: 0}
        end  
      end
	end
end