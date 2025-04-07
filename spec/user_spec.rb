require 'spec_helper'
require "#{File.dirname(__FILE__)}/../models/conector_api"
require "#{File.dirname(__FILE__)}/../models/user"

class ConectorApiFake
  def registrar(email, id)
    !!(email && id)
  end
end

describe 'User' do
  it 'deberia registrarse correctamente si tiene email y id' do
    api = ConectorApiFake.new
    result = User.new(api).registrar('pepe@pepito.com', 1)
    expect(result).to eq true
  end
end
