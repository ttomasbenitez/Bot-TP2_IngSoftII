class Recomendacion
  def initialize(artista_favorito, artista_recomendado)
    @artista_favorito = artista_favorito
    @artista_recomendado = artista_recomendado
  end

  def nombre_artista_favorito
    @artista_favorito.nombre
  end

  def nombre_artista_recomendado
    @artista_recomendado.nombre
  end
end
