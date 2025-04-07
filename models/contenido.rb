class Contenido
  attr_reader :id, :autor, :titulo, :duracion, :fecha_lanzamiento

  def initialize(nombre_autor, titulo, duracion, fecha_lanzamiento, id)
    @autor = Autor.new(nombre_autor)
    @titulo = titulo
    @duracion = duracion
    @fecha_lanzamiento = fecha_lanzamiento
    @id = id
  end

  def nombre_autor
    @autor.nombre
  end
end

class Cancion < Contenido
  def tipo
    'cancion'
  end
end

class Episodio < Contenido
  def tipo
    'episodio'
  end
end

class FabricaContenido
  def self.crear(tipo)
    return Cancion if tipo == 'cancion'

    return Episodio if tipo == 'episodio'
  end
end
