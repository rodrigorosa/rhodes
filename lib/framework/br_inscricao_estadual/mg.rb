module BrInscricaoEstadual
  class MG < Common

    def multiply(numero, peso)
      result = []
      numero.split('').collect(&:to_i).take(peso.size).each_with_index do |item, index|
         result << (item * peso[index])
      end
      result
    end

    def calculate_digito1(numero)
      # Acrescenta um zero a partir do 4o digito caso inscr conter apenas 6 digitos
      mun, inscr, estab = numero.match(/^(\d{3})(\d{6,7})(\d{2})\d{2}$/).captures
      numero = mun + inscr.rjust(7, '0') + estab

      # Soma os algarismos dos produtos
      soma = multiply(numero, self.class::PESO).
              collect{|r| r.to_s.split('')}.
              flatten.
              collect(&:to_i).
              inject(:+)

      # Soma deve ser subtraida da proxima dezena. Exemplo: Se soma for 38 =>  40 - 38 = 2
      result = (soma.to_f / 10.0).ceil * 10 - soma
      digit_verify_inscription(result)
    end

    def calculate_digito2(numero)
      # Soma os produtos
      soma = multiply(numero, self.class::PESO2).inject(:+)
      result = 11 - (soma % 11)
      digit_verify_inscription(result)
    end

    def digit_verify
      digito1 = calculate_digito1(self.insc_est)
      return false unless self.insc_est[-2].to_i == digito1 #[0,1].include?(digito1) &&

      digito2 = calculate_digito2(self.insc_est)
      return false unless self.insc_est[-1].to_i == digito2

      true
    end

    protected
      PESO =  [1, 2,  1,  2, 1, 2, 1, 2, 1, 2, 1, 2]
      PESO2 = [3, 2, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]
      STATE_INSC_SIZE = 13
      DIGITS_ZERO = [0, 10, 11]
  end
end
