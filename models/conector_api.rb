require 'faraday'
require 'dotenv/load'
require_relative 'contenido'
require_relative 'autor'
require_relative 'recomendacion'

class UsuarioNoRegistrado < StandardError
  def initialize(msg = 'Registrate para acceder a esta funcionalidad!')
    super
  end
end

class ContenidoNoExiste < StandardError
  def initialize(msg = 'El contenido no existe')
    super
  end
end

class ContenidoNoReproducido < StandardError
  def initialize(msg = 'Reproducí este contenido para darle me gusta')
    super
  end
end

class ContenidoDuplicado < StandardError
  def initialize(msg = 'El contenido ya se encuentra en la coleccion')
    super
  end
end

class ContenidoDuplicadoEnPlaylist < StandardError
  def initialize(msg = 'El contenido ya se encuentra en la playlist')
    super
  end
end

class MeGustaDuplicado < StandardError
  def initialize(msg = 'Ya le diste me gusta al contenido')
    super
  end
end

class EmailInvalido < StandardError
  def initialize(msg = 'Por favor ingresa un email valido')
    super
  end
end

class UsuarioDuplicado < StandardError
  def initialize(msg = 'Tu usuario ya esta registrado!')
    super
  end
end

class ContenidoInvalido < StandardError
  def initialize(msg = 'El contenido no puede agregarse a una playlist')
    super
  end
end

class SinContenidoPopular < StandardError
  def initialize(msg = 'No hay contenido popular para recomendarte')
    super
  end
end

class ValidadorAPI
  def self.chequear_error(error)
    errores = {
      'El usuario no existe' => UsuarioNoRegistrado,
      'El contenido no existe' => ContenidoNoExiste,
      'El contenido ya se encuentra en la coleccion' => ContenidoDuplicado,
      'El email no es valido' => EmailInvalido,
      'El usuario ya esta registrado' => UsuarioDuplicado,
      'El contenido no puede agregarse a una playlist' => ContenidoInvalido,
      'El contenido no fue reproducido por este usuario' => ContenidoNoReproducido,
      'No hay contenido popular' => SinContenidoPopular
    }

    raise errores[error] if errores.key?(error)
  end
end

class ConectorApi
  def initialize(logger)
    @url = ENV['API_URL'] || 'http://fake.com'
    @logger = logger
    @procesador_respuesta = ProcesadorRespuesta.new(logger)
  end

  def registrar(user_email, id_usuario)
    log_solicitud('usuarios', { email: user_email, id: id_usuario })
    respuesta = enviar_solicitud_post('usuarios', { email: user_email, id: id_usuario })
    @procesador_respuesta.procesar_respuesta_exito(respuesta, 201)
  end

  def novedades(username)
    @logger.debug("Solicitud a API - #{@url}/novedades")
    obtener_contenidos("novedades/#{username}")
  end

  def populares(username)
    @logger.debug("Solicitud a API - #{@url}/populares")
    obtener_contenidos("populares/#{username}")
  end

  def agregar_a_playlist(id_usuario, id_contenido)
    log_solicitud('playlist', { id_usuario:, id_contenido: })
    respuesta = enviar_solicitud_post('playlist', { id_usuario:, id_contenido: })
    @procesador_respuesta.procesar_respuesta(respuesta)
  rescue ContenidoDuplicado
    raise ContenidoDuplicadoEnPlaylist
  end

  def me_gusta(username, id_contenido)
    log_solicitud('me-gusta', { id_usuario: username, id_contenido: })
    respuesta = enviar_solicitud_post('me-gusta', { id_usuario: username, id_contenido: })
    @procesador_respuesta.procesar_respuesta(respuesta)
  rescue ContenidoDuplicado
    raise MeGustaDuplicado
  end

  def obtener_playlist(username)
    log_solicitud('playlist', { id_usuario: username })
    obtener_contenidos("playlist/#{username}")
  end

  def sugerencias(id_usuario)
    @logger.debug("Solicitud a API - #{@url}/sugerencias")
    respuesta = realizar_solicitud_get("sugerencias/#{id_usuario}")
    @procesador_respuesta.procesar_respuesta_sugerencias(respuesta, 'sugerencia')
  end

  def recomendaciones(id_usuario)
    @logger.debug("Solicitud a API - #{@url}/recomendaciones")
    respuesta = realizar_solicitud_get("recomendaciones/#{id_usuario}")
    @procesador_respuesta.procesar_respuesta_recomendacion(respuesta, 'favorito', 'recomendacion')
  end

  def obtener_contenido(id_contenido, username)
    endpoint = "#{@url}/contenido/#{id_contenido}"
    @logger.debug("Solicitud a API - #{endpoint}")
    respuesta = Faraday.get(endpoint) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['cid'] = Thread.current[:cid]
      req.params['id_usuario'] = username
    end
    @procesador_respuesta.procesar_respuesta(respuesta)
  end

  private

  def log_solicitud(endpoint, body)
    @logger.debug("Solicitud a API - #{@url}/#{endpoint} | Body: #{body}")
  end

  def enviar_solicitud_post(endpoint, body)
    Faraday.post("#{@url}/#{endpoint}") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['cid'] = Thread.current[:cid]
      req.body = body.to_json
    end
  end

  def realizar_solicitud_get(endpoint)
    Faraday.get("#{@url}/#{endpoint}") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['cid'] = Thread.current[:cid]
    end
  end

  def obtener_contenidos(endpoint)
    respuesta = realizar_solicitud_get(endpoint)
    respuesta_json = JSON.parse(respuesta.body)
    @logger.debug("Respuesta de API - Status: #{respuesta.status} | Body: #{respuesta_json}")

    ValidadorAPI.chequear_error(respuesta_json['error']) unless respuesta.status == 200

    respuesta_json.map { |contenido| @procesador_respuesta.construir_contenido(contenido) }
  end
end

class ProcesadorRespuesta
  def initialize(logger)
    @logger = logger
  end

  def procesar_respuesta_exito(respuesta, expected_status)
    body_respuesta = JSON.parse(respuesta.body)
    @logger.debug("Respuesta de API - Status: #{respuesta.status} | Body: #{body_respuesta}")
    ValidadorAPI.chequear_error(body_respuesta['error']) if respuesta.status != expected_status
    respuesta.success?
  end

  def procesar_respuesta_sugerencias(respuesta, sugerencia)
    contenido = JSON.parse(respuesta.body)
    @logger.debug("Respuesta de API - Status: #{respuesta.status} | Body: #{contenido}")

    raise UsuarioNoRegistrado if respuesta.status == 401

    return nil if contenido.empty?

    Autor.new(contenido[sugerencia])
  end

  def procesar_respuesta_recomendacion(respuesta, favorito, recomendacion)
    contenido = JSON.parse(respuesta.body)
    @logger.debug("Respuesta de API - Status: #{respuesta.status} | Body: #{contenido}")

    raise UsuarioNoRegistrado if respuesta.status == 401

    return nil if contenido.empty?

    Recomendacion.new(Autor.new(contenido[favorito]), Autor.new(contenido[recomendacion]))
  end

  def procesar_respuesta(respuesta)
    body_respuesta = JSON.parse(respuesta.body)
    @logger.debug("Respuesta de API - Status: #{respuesta.status} | Body: #{body_respuesta}")
    ValidadorAPI.chequear_error(body_respuesta['error']) if respuesta.status != 201
    construir_contenido(body_respuesta)
  end

  def construir_contenido(body_respuesta)
    FabricaContenido.crear(body_respuesta['tipo']).new(
      body_respuesta['autor'], body_respuesta['titulo'], body_respuesta['duracion'], body_respuesta['fecha_lanzamiento'], body_respuesta['id']
    )
  end
end
