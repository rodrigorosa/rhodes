module BrInscricaoEstadual
	class MT < Common
    protected
      PESO = [3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      STATE_INSC_SIZE = 11
      DIGITS_ZERO = [0,1,11]

		def initialize(insc_est)
			super(insc_est.rjust(11, '0'))
		end
	end
end