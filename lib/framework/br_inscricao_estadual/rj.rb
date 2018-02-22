module BrInscricaoEstadual
  class RJ < Common

    def calculate_verify(peso)
      result = calculate(peso)%11
      digit_verify_inscription(result)
    end

    def digit_verify_inscription(result)
      self.class::DIGITS_ZERO.include?(result) ? 0 : 11 - result
    end

    def digit_verify
      digito = calculate_verify(self.class::PESO)
      return false unless self.insc_est[(self.class::PESO.size)].to_i == digito

      true
    end

    protected
      DIGITS_ZERO = [0, 1]
      PESO = [2, 7, 6, 5, 4, 3, 2]
      STATE_INSC_SIZE = 8
  end
end
