require "#{File.dirname(__FILE__)}/../lib/routing"
require "#{File.dirname(__FILE__)}/../lib/version"
require "#{File.dirname(__FILE__)}/../models/conector_api"
require "#{File.dirname(__FILE__)}/../models/sistema_musica"

SIN_NOVEDADES = 'No hay novedades disponibles'.freeze
PLAYLIST_VACIA = 'Tu playlist está vacía'.freeze
PREFIJO_MENSAJE_SUGERENCIA = 'Te recomendamos a '.freeze
SIN_SUGERENCIAS = 'No hay sugerencias para vos'.freeze
SIN_RECOMENDACIONES = 'No tenemos recomendaciones para vos'.freeze

class FormateadorSalida
  def self.formatear_contenido(items)
    items.map { |item| "#{item.tipo}: #{item.nombre_autor} - #{item.titulo} (#{item.id})\n" }.join('')
  end

  def self.formatear_detalles_contenido(contenido)
    "ID: #{contenido.id}\n" \
    "Tipo: #{contenido.tipo}\n" \
    "Autor: #{contenido.nombre_autor}\n" \
    "Título: #{contenido.titulo}\n" \
    "Duración: #{contenido.duracion}\n" \
    "Fecha de lanzamiento: #{contenido.fecha_lanzamiento}\n"
  end
end

class EnvioBot
  def self.enviar_error(bot, message, error)
    bot.logger.debug("Respuesta a bot - #{error.message}")
    bot.api.send_message(chat_id: message.chat.id, text: error.message)
  end

  def self.enviar_mensaje(bot, message, mensaje)
    bot.logger.debug("Respuesta a bot - #{mensaje}")
    bot.api.send_message(chat_id: message.chat.id, text: mensaje)
  end
end

class Routes
  include Routing

  on_message '/start' do |bot, message|
    mensaje = "Hola, #{message.from.first_name}, soy el bot de gondor"
    EnvioBot.enviar_mensaje(bot, message, mensaje)
  end

  on_message '/version' do |bot, message|
    mensaje = Version.current
    EnvioBot.enviar_mensaje(bot, message, mensaje)
  end

  on_message_pattern %r{/registrar (?<email>.*)} do |bot, message, args|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    EnvioBot.enviar_mensaje(bot, message, "Bienvenido, #{args['email']}") if sistema.registrar_usuario(args['email'], message.from.username)
  rescue EmailInvalido, UsuarioDuplicado => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message_pattern %r{/agregar_a_playlist (?<id_contenido>.*)} do |bot, message, args|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    contenido = sistema.agregar_a_playlist(message.from.username, args['id_contenido'])
    EnvioBot.enviar_mensaje(bot, message, "Agregado a playlist: #{contenido.nombre_autor} - #{contenido.titulo}")
  rescue UsuarioNoRegistrado, ContenidoNoExiste, ContenidoDuplicadoEnPlaylist, ContenidoInvalido => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message_pattern %r{/me_gusta (?<id_contenido>.*)} do |bot, message, args|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))

    contenido = sistema.me_gusta(message.from.username, args['id_contenido'])
    mensaje_exito = "Le diste me gusta: #{contenido.nombre_autor} - #{contenido.titulo}"
    EnvioBot.enviar_mensaje(bot, message, mensaje_exito)
  rescue UsuarioNoRegistrado, ContenidoNoExiste, MeGustaDuplicado, ContenidoNoReproducido => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message '/agregar_a_playlist' do |bot, message|
    EnvioBot.enviar_mensaje(bot, message, 'Uso: /agregar_a_playlist <id_contenido>')
  end

  on_message '/me_gusta' do |bot, message|
    EnvioBot.enviar_mensaje(bot, message, 'Uso: /me_gusta <id_contenido>')
  end

  on_message '/novedades' do |bot, message|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    novedades = sistema.novedades(message.from.username)

    if novedades.empty?
      EnvioBot.enviar_mensaje(bot, message, SIN_NOVEDADES)
    else
      EnvioBot.enviar_mensaje(bot, message, FormateadorSalida.formatear_contenido(novedades))
    end

  rescue UsuarioNoRegistrado => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message '/popular' do |bot, message|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    populares = sistema.populares(message.from.username)
    EnvioBot.enviar_mensaje(bot, message, FormateadorSalida.formatear_contenido(populares))
  rescue UsuarioNoRegistrado, SinContenidoPopular => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message_pattern %r{/detalle (?<id_contenido>.*)} do |bot, message, args|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    contenido = sistema.obtener_contenido(args['id_contenido'], message.from.username)
    EnvioBot.enviar_mensaje(bot, message, FormateadorSalida.formatear_detalles_contenido(contenido))
  rescue UsuarioNoRegistrado, ContenidoNoExiste => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message '/ver_playlist' do |bot, message|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    playlist = sistema.obtener_playlist(message.from.username)

    if playlist.empty?
      EnvioBot.enviar_mensaje(bot, message, PLAYLIST_VACIA)
    else
      EnvioBot.enviar_mensaje(bot, message, FormateadorSalida.formatear_contenido(playlist))
    end

  rescue UsuarioNoRegistrado => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message '/sugerencia' do |bot, message|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    sugerencia = sistema.sugerencias(message.from.username)
    if sugerencia.nil?
      EnvioBot.enviar_mensaje(bot, message, SIN_SUGERENCIAS)
    else
      mensaje = PREFIJO_MENSAJE_SUGERENCIA + sugerencia.nombre
      EnvioBot.enviar_mensaje(bot, message, mensaje)
    end

  rescue UsuarioNoRegistrado => e
    EnvioBot.enviar_error(bot, message, e)
  end

  on_message '/recomendacion' do |bot, message|
    sistema = SistemaMusica.new(ConectorApi.new(bot.logger))
    recomendacion = sistema.recomendaciones(message.from.username)
    if recomendacion.nil?
      EnvioBot.enviar_mensaje(bot, message, SIN_RECOMENDACIONES)
    else
      EnvioBot.enviar_mensaje(bot, message, "Como tu artista con mas me gusta es #{recomendacion.nombre_artista_favorito} entonces te recomendamos a #{recomendacion.nombre_artista_recomendado}")
    end
  rescue UsuarioNoRegistrado => e
    EnvioBot.enviar_error(bot, message, e)
  end

  default do |bot, message|
    EnvioBot.enviar_mensaje(bot, message, 'Uh? No te entiendo! Me repetis la pregunta?')
  end
end
