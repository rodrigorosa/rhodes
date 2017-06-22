module BrInscricaoEstadual
	class Base
		def initialize(inscricao,uf)
	  	self.kclass = BrInscricaoEstadual.const_get(safe_object(uf)).new(inscricao)
	  end

	  def valid?
	  	kclass.valid?
	  end

		protected
			def kclass
				@kclass
			end

			def kclass=(kclass)
				@kclass = kclass
			end

	  private
	  	def safe_object(camel_cased_word)
	  		raise unless camel_cased_word =~ /\A[A-Za-z]{2}\z/
        camel_cased_word.upcase
      end

	end
end