module BrInscricaoEstadual
	class Common
    DIGITS_ZERO = [0,1,10,11] 
    STATE_INSC_SIZE = 9
    PESO = [9, 8, 7, 6, 5, 4, 3, 2]
    
		attr_accessor :insc_est

		def initialize(insc_est)
      self.insc_est = insc_est.gsub(/\D*/,'')
    end

    def valid?
      self.class.const_defined?('STATE_CODE') ? (size_verify && state_code && digit_verify) : (size_verify && digit_verify)
    end

		def calculate_verify(peso)
      result = (11 - calculate(peso)%11)
			digit_verify_inscription(result)      
    end

    def calculate(peso)
    	@calc = []
    	self.insc_est.split('').collect(&:to_i).take(peso.size).each_with_index{|item, index| @calc << (item * peso[index]) }
    	@calc.inject(:+)
    end

    def digit_verify_inscription(result)
    	self.class::DIGITS_ZERO.include?(result) ? 0 : result
    end

    def state_code
      return self.insc_est[0..1] == self.class::STATE_CODE if self.class::STATE_CODE.is_a?(String)
      return self.class::STATE_CODE.include?(self.insc_est[0..1]) if self.class::STATE_CODE.is_a?(Array)
    end

    def digit_verify
      digito1 = calculate_verify(self.class::PESO)
      self.class::const_set('DIGITO_LEVEL1', self.class::PESO.size) unless self.class.const_defined?('DIGITO_LEVEL1')
      return false unless self.insc_est[(self.class::DIGITO_LEVEL1)].to_i == digito1 #[0,1].include?(digito1) &&

      if self.class.const_defined?('PESO2')
        digito2 = calculate_verify(self.class::PESO2)
        self.class::const_set('DIGITO_LEVEL2', self.class::PESO2.size) unless self.class.const_defined?('DIGITO_LEVEL2')
        return false unless self.insc_est[(self.class::DIGITO_LEVEL2)].to_i == digito2 #[0,2].include?(digito2) &&
      end

      true
    end

    def size_verify
    	self.insc_est.size == self.class::STATE_INSC_SIZE
  	end

	end
end