require 'spec_helper'
require 'web_mock'
# Uncomment to use VCR
# require 'vcr_helper'

require "#{File.dirname(__FILE__)}/../app/bot_client"

API_URL = ENV['API_URL'] || 'http://fake.com'

def when_i_send_text(token, message_text)
  body = { "ok": true, "result": [{ "update_id": 693_981_718,
                                    "message": { "message_id": 11,
                                                 "from": { "id": 121212, "is_bot": false, "first_name": 'Emilio', "last_name": 'test_lastname', "username": 'test_username', "language_code": 'en' },
                                                 "chat": { "id": 121212, "first_name": 'Emilio', "last_name": 'test_lastname', "username": 'test_username', "type": 'private' },
                                                 "date": 1_557_782_998, "text": message_text,
                                                 "entities": [{ "offset": 0, "length": 6, "type": 'bot_command' }] } }] }

  stub_request(:any, "https://api.telegram.org/bot#{token}/getUpdates")
    .to_return(body: body.to_json, status: 200, headers: { 'Content-Length' => 3 })
end

def then_i_get_text(token, message_text)
  body = { "ok": true,
           "result": { "message_id": 12,
                       "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                       "chat": { "id": 121212, "first_name": 'Emilio', "last_name": 'test_lastname', "username": 'test_username', "type": 'private' },
                       "date": 1_557_782_999, "text": message_text } }

  stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
    .with(
      body: { 'chat_id' => '121212', 'text' => message_text }
    )
    .to_return(status: 200, body: body.to_json, headers: {})
end

def when_i_register_user(user_email)
  body = { "email": user_email, id: 'test_username' }
  stub_request(:post, "#{API_URL}/usuarios")
    .to_return(body: body.to_json, status: 201)
end

def cuando_consulto_por_novedades(username)
  body = [
    {
      id: 1,
      autor: 'Shakira',
      titulo: 'Waka waka',
      tipo: 'cancion',
      fecha_lanzamiento: '2024-01-01',
      duracion: '3:30'
    },
    {
      id: 2,
      autor: 'Shakira',
      titulo: 'Loba',
      tipo: 'cancion',
      fecha_lanzamiento: '2024-01-01',
      duracion: '3:30'
    },
    {
      id: 3,
      autor: 'Shakira',
      titulo: 'Suerte',
      tipo: 'cancion',
      fecha_lanzamiento: '2024-01-01',
      duracion: '3:30'
    }
  ]
  stub_request(:get, "#{API_URL}/novedades/#{username}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_consulto_por_novedades_sin_estar_registrado
  body = { 'error': 'El usuario no existe' }
  stub_request(:get, "#{API_URL}/novedades/test_username")
    .to_return(body: body.to_json, status: 401)
end

def cuando_consulto_novedades_sin_novedades(id_usuario)
  body = []
  stub_request(:get, "#{API_URL}/novedades/#{id_usuario}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_agrego_cancion_a_playlist_con_id(id_contenido, autor, titulo)
  body = { 'tipo': 'cancion', 'autor': autor, 'titulo': titulo }
  stub_request(:post, "#{API_URL}/playlist")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 201)
end

def cuando_agrego_podcast_a_playlist_con_id(id_contenido)
  body = { error: 'El contenido no puede agregarse a una playlist' }
  stub_request(:post, "#{API_URL}/playlist")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 400)
end

def cuando_agrego_cancion_duplicada_a_playlist_con_id(id_contenido)
  body = { error: 'El contenido ya se encuentra en la coleccion' }
  stub_request(:post, "#{API_URL}/playlist")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 400)
end

def cuando_doy_me_gusta_dos_veces_a_contenido_con_id(id_contenido)
  body = { error: 'El contenido ya se encuentra en la coleccion' }
  stub_request(:post, "#{API_URL}/me-gusta")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 400)
end

def cuando_doy_me_gusta_a_contenido_no_reproducido_con_id(id_contenido)
  body = { error: 'El contenido no fue reproducido por este usuario' }
  stub_request(:post, "#{API_URL}/me-gusta")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 400)
end

def cuando_agrego_cancion_a_playlist_sin_estar_registrado_con_id(id_contenido)
  body = { 'error': 'El usuario no existe' }
  stub_request(:post, "#{API_URL}/playlist")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 401)
end

def cuando_agrego_cancion_inexistente_a_playlist(id_contenido)
  body = { 'error': 'El contenido no existe' }
  stub_request(:post, "#{API_URL}/playlist")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 400)
end

def cuando_pido_detalle_de_cancion_inexistente(id_contenido)
  body = { 'error': 'El contenido no existe' }
  stub_request(:get, "#{API_URL}/contenido/#{id_contenido}?id_usuario=test_username")
    .to_return(body: body.to_json, status: 400)
end

def cuando_consulto_por_playlist_sin_estar_registrado
  body = { 'error': 'El usuario no existe' }
  stub_request(:get, "#{API_URL}/playlist/test_username")
    .to_return(body: body.to_json, status: 401)
end

def cuando_doy_megusta_a_contenido_inexistente_con_id(id_contenido)
  body = { 'error': 'El contenido no existe' }
  stub_request(:post, "#{API_URL}/me-gusta")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 400)
end

def cuando_doy_me_gusta_a_contenido_con_id(id_contenido)
  body = { 'tipo': 'cancion', 'autor': 'Shakira', 'titulo': 'Waka waka' }
  stub_request(:post, "#{API_URL}/me-gusta")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 201)
end

def cuando_doy_me_gusta_a_contenido_con_id_sin_estar_registrado(id_contenido)
  body = { 'error': 'El usuario no existe' }
  stub_request(:post, "#{API_URL}/me-gusta")
    .with(
      body: hash_including('id_usuario' => anything, 'id_contenido' => id_contenido.to_s)
    )
    .to_return(body: body.to_json, status: 401)
end

def cuando_consulto_por_playlist_con_una_cancion(id_usuario)
  body = [
    { id: 1, autor: 'Shakira', titulo: 'Waka waka', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' }
  ]
  stub_request(:get, "#{API_URL}/playlist/#{id_usuario}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_existe_el_contenido_con_id(id_contenido)
  body = { 'id': id_contenido, 'tipo': 'cancion', 'autor': 'Shakira', 'titulo': 'Waka waka', 'duracion': '3:30', 'fecha_lanzamiento': '2010-05-07' }
  stub_request(:get, "#{API_URL}/contenido/#{id_contenido}")
    .with(
      query: hash_including('id_usuario' => anything)
    )
    .to_return(body: body.to_json, status: 200)
end

def cuando_existe_el_podcast_con_id(id_contenido)
  body = { 'id': id_contenido, 'tipo': 'episodio', 'autor': 'Olga', 'titulo': 'Episodio 500', 'duracion': '1:33:30', 'fecha_lanzamiento': '2024-05-07' }
  stub_request(:get, "#{API_URL}/contenido/#{id_contenido}")
    .with(
      query: hash_including('id_usuario' => anything)
    )
    .to_return(body: body.to_json, status: 200)
end

def cuando_consulto_por_playlist_con_cinco_canciones(id_usuario)
  body = [
    { id: 1, autor: 'Shakira', titulo: 'Waka waka', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 2, autor: 'Shakira', titulo: 'Loba', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 3, autor: 'Shakira', titulo: 'Suerte', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 4, autor: 'Shakira', titulo: 'La Tortura', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 5, autor: 'Shakira', titulo: 'La Bicicleta', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' }
  ]

  stub_request(:get, "#{API_URL}/playlist/#{id_usuario}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_consulto_por_playlist_vacia(id_usuario)
  body = []

  stub_request(:get, "#{API_URL}/playlist/#{id_usuario}")
    .to_return(body: body.to_json, status: 200)
end

def obetener_cinco_canciones
  "cancion: Shakira - Waka waka (1)\n" \
                 "cancion: Shakira - Loba (2)\n" \
                 "cancion: Shakira - Suerte (3)\n" \
                 "cancion: Shakira - La Tortura (4)\n" \
                 "cancion: Shakira - La Bicicleta (5)\n"
end

def detalles_wakawaka
  "ID: 1\n" \
  "Tipo: cancion\n" \
  "Autor: Shakira\n" \
  "Título: Waka waka\n" \
  "Duración: 3:30\nFecha de lanzamiento: 2010-05-07\n"
end

def detalles_olga
  "ID: 1\n" \
  "Tipo: episodio\n" \
  "Autor: Olga\n" \
  "Título: Episodio 500\n" \
  "Duración: 1:33:30\nFecha de lanzamiento: 2024-05-07\n"
end

def cuando_consulto_por_sugerencia_sin_estar_registrado(id_usuario)
  body = { 'error': 'El usuario no existe' }
  stub_request(:get, "#{API_URL}/sugerencias/#{id_usuario}")
    .to_return(body: body.to_json, status: 401)
end

def cuando_consulto_por_detalle_de_contenido_sin_estar_registrado(id_usuario)
  body = { 'error': 'El usuario no existe' }
  stub_request(:get, "#{API_URL}/contenido/1?id_usuario=#{id_usuario}")
    .to_return(body: body.to_json, status: 401)
end

def cuando_consulto_por_sugerencia_con_playlist_con_contenido(id_usuario, autor)
  body = { 'sugerencia': autor }
  stub_request(:get, "#{API_URL}/sugerencias/#{id_usuario}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_consulto_por_sugerencia_con_playlist_sin_contenido(id_usuario)
  stub_request(:get, "#{API_URL}/sugerencias/#{id_usuario}")
    .to_return(body: '{}', status: 200)
end

def cuando_consulto_por_recomendacion_con_varios_me_gusta(id_usuario, artista_favorito, artista_recomendado)
  body = { 'favorito': artista_favorito, 'recomendacion': artista_recomendado }
  stub_request(:get, "#{API_URL}/recomendaciones/#{id_usuario}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_consulto_por_recomendacion_sin_estar_registrado(id_usuario)
  body = { 'error': 'El usuario no existe' }
  stub_request(:get, "#{API_URL}/recomendaciones/#{id_usuario}")
    .to_return(body: body.to_json, status: 401)
end

def cuando_consulto_por_recomendacion_sin_me_gusta(username)
  body = {}
  stub_request(:get, "#{API_URL}/recomendaciones/#{username}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_me_registro_con_email_invalido(email)
  body = { error: 'El email no es valido' }
  stub_request(:post, "#{API_URL}/usuarios")
    .with(
      body: { email:, id: 'test_username' }
    ).to_return(body: body.to_json, status: 400)
end

def cuando_me_registro_por_segunda_vez
  body = { error: 'El usuario ya esta registrado' }
  stub_request(:post, "#{API_URL}/usuarios")
    .with(
      body: { email: 'pepe@pepito.com', id: 'test_username' }
    ).to_return(body: body.to_json, status: 400)
end

def cuando_consulto_por_populares_y_hay_uno_solo(username)
  body = [
    {
      id: 1,
      autor: 'Shakira',
      titulo: 'Waka waka',
      tipo: 'cancion',
      fecha_lanzamiento: '2024-01-01',
      duracion: '3:30'
    }
  ]
  stub_request(:get, "#{API_URL}/populares/#{username}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_consulto_por_populares_y_hay_varios(username)
  body = [
    { id: 1, autor: 'Shakira', titulo: 'Waka waka', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 2, autor: 'Shakira', titulo: 'Loba', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 3, autor: 'Shakira', titulo: 'Suerte', tipo: 'cancion', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 4, autor: 'Olga', titulo: 'Episodio 3', tipo: 'episodio', fecha_lanzamiento: '2024-01-01', duracion: '3:30' },
    { id: 5, autor: 'U2', titulo: 'Beautiful day', tipo: 'cancion', fecha_lanzamiento: '1990-01-01', duracion: '3:30' }
  ]
  stub_request(:get, "#{API_URL}/populares/#{username}")
    .to_return(body: body.to_json, status: 200)
end

def cuando_consulto_por_popular_sin_estar_registrado(username)
  body = { 'error': 'El usuario no existe' }
  stub_request(:get, "#{API_URL}/populares/#{username}")
    .to_return(body: body.to_json, status: 401)
end

def cuando_consulto_por_popular_sin_haber_populares(username)
  body = { 'error': 'No hay contenido popular' }
  stub_request(:get, "#{API_URL}/populares/#{username}")
    .to_return(body: body.to_json, status: 400)
end

def populares_esperado
  "cancion: Shakira - Waka waka (1)\n" \
    "cancion: Shakira - Loba (2)\n" \
    "cancion: Shakira - Suerte (3)\n" \
    "episodio: Olga - Episodio 3 (4)\n" \
    "cancion: U2 - Beautiful day (5)\n"
end

def run_bot(token)
  app = BotClient.new(token)
  app.run_once
end

describe 'BotClient' do
  let(:token) { 'fake_token' }

  it 'should get a /version message and respond with current version' do
    token = 'fake_token'

    when_i_send_text(token, '/version')
    then_i_get_text(token, Version.current)

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a /start message and respond with Hola' do
    token = 'fake_token'

    when_i_send_text(token, '/start')
    then_i_get_text(token, 'Hola, Emilio, soy el bot de gondor')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get an unknown message message and respond with Do not understand' do
    token = 'fake_token'

    when_i_send_text(token, '/desconocido')
    then_i_get_text(token, 'Uh? No te entiendo! Me repetis la pregunta?')

    app = BotClient.new(token)

    app.run_once
  end

  it 'obtiene un mensaje /registrar <email> y responde Bienvenido, <email>' do
    token = 'fake_token'

    when_i_send_text(token, '/registrar pepe@pepito.com')
    when_i_register_user('pepe@pepito.com')
    then_i_get_text(token, 'Bienvenido, pepe@pepito.com')

    run_bot(token)
  end

  it 'obtiene un mensaje /registrar <email> para un email invalido' do
    texto_esperado = 'Por favor ingresa un email valido'

    when_i_send_text('fake_token', '/registrar pe|pe@pep_ito.com')
    cuando_me_registro_con_email_invalido('pe|pe@pep_ito.com')
    then_i_get_text('fake_token', texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /registrar <email> para un usuario ya registrado' do
    texto_esperado = 'Tu usuario ya esta registrado!'

    when_i_send_text('fake_token', '/registrar pepe@pepito.com')
    cuando_me_registro_por_segunda_vez
    then_i_get_text('fake_token', texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /novedades por un usuario registrado y muestra novedades' do
    texto_esperado = "cancion: Shakira - Waka waka (1)\ncancion: Shakira - Loba (2)\ncancion: Shakira - Suerte (3)\n"

    when_i_send_text(token, '/novedades')
    cuando_consulto_por_novedades('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /novedades por un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    when_i_send_text(token, '/novedades')
    cuando_consulto_por_novedades_sin_estar_registrado
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /novedades por un usuario y no hay novedades ' do
    texto_esperado = 'No hay novedades disponibles'

    when_i_send_text(token, '/novedades')
    cuando_consulto_novedades_sin_novedades('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /agregar_a_playlist 1 y el contenido se agrega a la playlist' do
    texto_esperado = 'Agregado a playlist: Shakira - Waka waka'

    when_i_send_text(token, '/agregar_a_playlist 1')
    cuando_agrego_cancion_a_playlist_con_id(1, 'Shakira', 'Waka waka')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /agregar_a_playlist 1 por un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    when_i_send_text(token, '/agregar_a_playlist 1')
    cuando_agrego_cancion_a_playlist_sin_estar_registrado_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /agregar_a_playlist y no se se especifica contenido' do
    texto_esperado = 'Uso: /agregar_a_playlist <id_contenido>'

    when_i_send_text(token, '/agregar_a_playlist')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /agregar_a_playlist 1 y el contenido no existe' do
    texto_esperado = 'El contenido no existe'

    when_i_send_text(token, '/agregar_a_playlist 1')
    cuando_agrego_cancion_inexistente_a_playlist(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /agregar_a_playlist 1 pero el contenido es un podcast' do
    texto_esperado = 'El contenido no puede agregarse a una playlist'

    when_i_send_text(token, '/agregar_a_playlist 1')
    cuando_agrego_podcast_a_playlist_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /agregar_a_playlist 1 y el contenido ya estaba en la playlist' do
    texto_esperado = 'El contenido ya se encuentra en la playlist'

    when_i_send_text(token, '/agregar_a_playlist 1')
    cuando_agrego_cancion_duplicada_a_playlist_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /megusta 1 y se agrega un like del usuario' do
    texto_esperado = 'Le diste me gusta: Shakira - Waka waka'

    when_i_send_text(token, '/me_gusta 1')
    cuando_doy_me_gusta_a_contenido_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /megusta 1 por un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    when_i_send_text(token, '/me_gusta 1')
    cuando_doy_me_gusta_a_contenido_con_id_sin_estar_registrado(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /megusta y no se especifica contenido' do
    texto_esperado = 'Uso: /me_gusta <id_contenido>'

    when_i_send_text(token, '/me_gusta')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /me_gusta 1 y el contenido no existe' do
    texto_esperado = 'El contenido no existe'

    when_i_send_text(token, '/me_gusta 1')
    cuando_doy_megusta_a_contenido_inexistente_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene mensaje /me_gusta 1 y la cancion ya tenia un me gusta' do
    texto_esperado = 'Ya le diste me gusta al contenido'

    when_i_send_text(token, '/me_gusta 1')
    cuando_doy_me_gusta_dos_veces_a_contenido_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene mensaje /ver_playlist y devuelve la playlist personal con una cancion' do
    texto_esperado = "cancion: Shakira - Waka waka (1)\n"

    when_i_send_text(token, '/ver_playlist')
    cuando_consulto_por_playlist_con_una_cancion('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene mensaje /ver_playlist y devuelve la playlist personal con 5 canciones' do
    texto_esperado = obetener_cinco_canciones

    when_i_send_text(token, '/ver_playlist')
    cuando_consulto_por_playlist_con_cinco_canciones('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene mensaje /ver_playlist pero la playlist esta vacia' do
    texto_esperado = 'Tu playlist está vacía'

    when_i_send_text(token, '/ver_playlist')
    cuando_consulto_por_playlist_vacia('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /ver_playlist por un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    when_i_send_text(token, '/ver_playlist')
    cuando_consulto_por_playlist_sin_estar_registrado
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /sugerencia por un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    when_i_send_text(token, '/sugerencia')
    cuando_consulto_por_sugerencia_sin_estar_registrado('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /sugerencia por un usuario registrado con playlist con canciones' do
    cuando_agrego_cancion_a_playlist_con_id(5, 'Lady Gaga', 'Una cancion')
    cuando_consulto_por_sugerencia_con_playlist_con_contenido('test_username', 'Lady Gaga')

    when_i_send_text(token, '/sugerencia')
    then_i_get_text(token, 'Te recomendamos a Lady Gaga')

    run_bot(token)
  end

  it 'obtiene un mensaje /sugerencia por un usuario registrado con playlist sin canciones' do
    texto_esperado = 'No hay sugerencias para vos'
    cuando_consulto_por_sugerencia_con_playlist_sin_contenido('test_username')

    when_i_send_text(token, '/sugerencia')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /recomendacion por un usuario con varios me gusta' do
    texto_esperado = 'Como tu artista con mas me gusta es Charly Garcia entonces te recomendamos a Pedro Aznar'

    cuando_consulto_por_recomendacion_con_varios_me_gusta('test_username', 'Charly Garcia', 'Pedro Aznar')
    when_i_send_text(token, '/recomendacion')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /me_gusta por un usuario que no reprodujo el contenido' do
    texto_esperado = 'Reproducí este contenido para darle me gusta'

    when_i_send_text(token, '/me_gusta 4')
    cuando_doy_me_gusta_a_contenido_no_reproducido_con_id(4)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /detalle con un id de una cancion y devuelve los detalles' do
    texto_esperado = detalles_wakawaka

    when_i_send_text(token, '/detalle 1')
    cuando_existe_el_contenido_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /detalle con un id de un episodio y devuelve los detalles' do
    texto_esperado = detalles_olga

    when_i_send_text(token, '/detalle 1')
    cuando_existe_el_podcast_con_id(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /detalle de un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    when_i_send_text(token, '/detalle 1')
    cuando_consulto_por_detalle_de_contenido_sin_estar_registrado('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /detalle 1 y el contenido no existe' do
    texto_esperado = 'El contenido no existe'

    when_i_send_text(token, '/detalle 1')
    cuando_pido_detalle_de_cancion_inexistente(1)
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /popular por un usuario registrado y muestra el único popular' do
    texto_esperado = "cancion: Shakira - Waka waka (1)\n"

    when_i_send_text(token, '/popular')
    cuando_consulto_por_populares_y_hay_uno_solo('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /popular por un usuario registrado y muestra populares' do
    texto_esperado = populares_esperado

    when_i_send_text(token, '/popular')
    cuando_consulto_por_populares_y_hay_varios('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /popular de un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    when_i_send_text(token, '/popular')
    cuando_consulto_por_popular_sin_estar_registrado('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /popular de un usuario registrado sin haber populares' do
    texto_esperado = 'No hay contenido popular para recomendarte'

    when_i_send_text(token, '/popular')
    cuando_consulto_por_popular_sin_haber_populares('test_username')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /recomendacion por un usuario no registrado' do
    texto_esperado = 'Registrate para acceder a esta funcionalidad!'

    cuando_consulto_por_recomendacion_sin_estar_registrado('test_username')
    when_i_send_text(token, '/recomendacion')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end

  it 'obtiene un mensaje /recomendacion por un usuario sin me gusta' do
    texto_esperado = 'No tenemos recomendaciones para vos'

    cuando_consulto_por_recomendacion_sin_me_gusta('test_username')
    when_i_send_text(token, '/recomendacion')
    then_i_get_text(token, texto_esperado)

    run_bot(token)
  end
end
