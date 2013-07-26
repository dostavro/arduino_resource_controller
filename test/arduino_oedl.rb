
defEvent :arduino_created do |state|
  state.find_all do |v|
    v[:type] == 'arduino' && !v[:membership].empty?
  end.size > 0
end

defGroup('sensors', 'arduino_rc')

onEvent :ALL_UP do
  group('sensors') do |g|
    g.create_resource('gateway', { type: 'arduino', host: "10.64.44.240", interval: 2 })

    onEvent :arduino_created do
      info ">>> Arduino created"
      g.resources[type: 'arduino'].topic.on_inform do |msg|
        msg.each_property do |name, value|
          logger.info "#{name} => #{value}"
        end
      end

      after 6.seconds do
        g.resources[type: 'arduino'].interval = 1
      end

      every 5.second do
        g.resources[type: 'arduino'].interval
      end
    end

    after 30.seconds do
      info "Release arduino"
      g.resources[type: 'arduino'].release
      done!
    end

  end
end
