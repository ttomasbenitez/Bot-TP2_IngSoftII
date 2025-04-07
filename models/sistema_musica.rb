require_relative 'user'

class SistemaMusica
  def initialize(adaptador)
    @adaptador = adaptador
  end

  def registrar_usuario(email, id)
    User.new(@adaptador).registrar(email, id)
  end

  def novedades(id_usuario)
    @adaptador.novedades(id_usuario)
  end

  def agregar_a_playlist(username, id_contenido)
    @adaptador.agregar_a_playlist(username, id_contenido)
  end

  def me_gusta(username, id_contenido)
    @adaptador.me_gusta(username, id_contenido)
  end

  def obtener_contenido(id_contenido, username)
    @adaptador.obtener_contenido(id_contenido, username)
  end

  def obtener_playlist(username)
    @adaptador.obtener_playlist(username)
  end

  def populares(username)
    @adaptador.populares(username)
  end

  def sugerencias(username)
    @adaptador.sugerencias(username)
  end

  def recomendaciones(username)
    @adaptador.recomendaciones(username)
  end
end
