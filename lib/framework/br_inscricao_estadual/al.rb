module BrInscricaoEstadual
	class AL < Common
    def valid?
     super && type
    end

    protected
      STATE_CODE = "24"
      DIGITS_ZERO = [10]

      def type  
        %w(0 3 5 7 8).include?(self.insc_est[2])
      end
	end
end