require 'omf_rc'
require 'nokogiri'
require 'open-uri'

module OmfRc::ResourceProxy::ArduinoFactory
  include OmfRc::ResourceProxyDSL

  register_proxy :arduino_factory
end

module OmfRc::ResourceProxy::Arduino
  include OmfRc::ResourceProxyDSL

  register_proxy :arduino, :create_by => :arduino_factory

  property :interval, default: 1
  property :host

  hook :after_initial_configured do |arduino|
    arduino.send_command("led_on")
  end

  hook :before_release do |arduino|
    arduino.send_command("led_off")
  end

  request :interval do |arduino|
    arduino.send_command("led")
  end

  configure :interval do |arduino, value|
    res = arduino.send_command("led?interval=#{value}")
    arduino.property.interval = value
    res
  end

  work :send_command do |arduino, command|
    doc = Nokogiri::HTML(open("http://#{arduino.property.host}/#{command}"))
    res = doc.xpath('//p').text.strip
    res
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://alpha:pw@localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Arduino controller >> Connected to XMPP server"
    arduino = OmfRc::ResourceFactory.create(:arduino_factory, uid: 'arduino_factory')
    comm.on_interrupted { arduino.disconnect }
  end
end
