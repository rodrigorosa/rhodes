module BrInscricaoEstadual
	class TO < Common
		def valid?
     super && type
    end

    def initialize(insc_est)
      insc_est.gsub!(/\D/, "")
      if insc_est.size == 9
        #Quando informados apenas 9 dígitos então entende-se que o tipo (opcional - 3o e 4o dígitos)
        # não foi informado e emulamos o cálculo utilizando um "tipo" válido
        first, last = insc_est.match(/(\d{2})(\d{7})/).captures
        super("#{first}01#{last}")
      else
        super(insc_est)
      end
    end


		protected
			PESO = [9, 8, 0, 0, 7, 6, 5, 4, 3, 2]
			STATE_INSC_SIZE = 11
			DIGITS_ZERO = [0,1,10,11]

		  def type  
        %w(01 02 03 99).include?(self.insc_est[2..3])
      end
  end
end