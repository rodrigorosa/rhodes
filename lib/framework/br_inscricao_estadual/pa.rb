module BrInscricaoEstadual
  class PA < Common
    STATE_CODE = '15'
    DIGITS_ZERO = [0, 1]

    # @override temporario até refatoração completa da gem
    def digit_verify
      true
    end
  end
end
