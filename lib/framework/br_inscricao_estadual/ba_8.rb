module BrInscricaoEstadual
	class BA8 < Common
    include BACommon

		protected
			PESO2 = [7, 6, 5, 4, 3, 2]
			PESO = [8, 7, 6, 5, 4, 3, 0, 2]
			STATE_INSC_SIZE = 8
			DIGITS_ZERO = [0,10,11]
      DIGITO_LEVEL1=6
      DIGITO_LEVEL2=7
		
  end
end