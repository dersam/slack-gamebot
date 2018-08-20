module SlackGamebot
  class Server < SlackRubyBotServer::Server
    @server_map = {}

    def self.server_map
      @server_map
    end

    def initialize(attrs = {})
      attrs = attrs.dup
      attrs[:aliases] = ([attrs[:team].game.name] + [attrs[:team].aliases]).flatten.compact
      attrs[:send_gifs] = attrs[:team].gifs
      super attrs
    end

    on :hello do |client, data|
      socket = client.instance_variable_get(:@socket)
      driver = socket.instance_variable_get(:@driver) if socket
      logger.info [driver.object_id, "Now associated with #{client.team.id}."]
      @server_map[client.team.id] = driver
    end

    on :user_change do |client, data|
      user = User.where(team: client.owner, user_id: data.user.id).first
      next unless user && user.user_name != data.user.name
      logger.info "RENAME: #{user.user_id}, #{user.user_name} => #{data.user.name}"
      user.update_attributes!(user_name: data.user.name)
    end

    on :channel_joined do |client, data|
      logger.info "#{client.owner.name}: joined ##{data.channel['name']}."
      message = <<-EOS.freeze
Hi! I am your friendly game bot. Register with `@#{client.self.name} register`.
Challenge someone to a game of #{client.owner.game.name} with `@#{client.self.name} challenge @someone`.
Type `@#{client.self.name} help` fore more commands and don't forget to have fun at work!
      EOS
      client.say(channel: data.channel['id'], text: message)
    end
  end
end
