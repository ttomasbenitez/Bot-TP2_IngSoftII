class User
  def initialize(adaptador)
    @adaptador = adaptador
  end

  def registrar(email, id)
    @adaptador.registrar(email, id)
  end
end
