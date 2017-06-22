module BrInscricaoEstadual
	class SP < Common
		attr_accessor :contryside

		def initialize(insc_est)
			self.contryside = insc_est.start_with?("P","p")
  	  self.insc_est = insc_est.gsub(/\D*/,'')
	  end

	  def valid?
	  	self.contryside ? SPP.new(self.insc_est).valid? : super
    end

		protected
			PESO = [1, 3, 4, 5, 6, 7, 8, 10]
			PESO2= [3, 2, 10, 9, 8, 7, 6, 5, 4, 3, 2]
			STATE_INSC_SIZE = 12
			DIGITS_ZERO = [0,10,11]


			def calculate_verify(peso)
      	result = calculate(peso)%11
				digit_verify_inscription(result)      
    	end

  end
end