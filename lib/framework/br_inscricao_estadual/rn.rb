module BrInscricaoEstadual
	class RN < Common
		def valid?
    	return (self.insc_est.size == 9) ? RN9.new(insc_est).valid? : RN10.new(insc_est).valid?
    end
  
	end
end