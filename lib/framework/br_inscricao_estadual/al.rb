module BrInscricaoEstadual
  class AL < Common
    def valid?
      super && type
    end

    protected

    STATE_CODE = "24"
    DIGITS_ZERO = [10]

    def type  
      # %w(0 3 5 7 8).include?(self.insc_est[2])
      # validação removida pois existem casos de inscricoes validas
      # com digitos 6 ou 4, porem o site do estado de alagoas nao
      # disponibiliza informacao atualizada sobre a validacao
      true
    end
  end
end
