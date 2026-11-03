# byteslice here wouldn't be functional because it returns a new string instead of modifying ur original string

require "json"
require "webrick"
require_relative "memory"

module MemoryService
  MAX_BODY_BYTES = 1024

  def self.build_server(port: 8765)
    server = WEBrick::HTTPServer.new(
      BindAddress: "127.0.0.1",
      Port: port,
      MaxClients: 4,
      AccessLog: [],
      Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN)
    )

    server.mount_proc "/health" do |request, response|
      if request.request_method == "GET"
        write_json(response, 200, "status" => "ok")
      else
        write_json(response, 405, "error" => "method not allowed")
      end
    end

    server.mount_proc "/dispatch" do |request, response|
      if request.request_method != "POST"
        write_json(response, 405, "error" => "method not allowed")
        next
      end

      body = request.body.to_s
      if body.bytesize > MAX_BODY_BYTES
        write_json(response, 413, "error" => "request too large")
        next
      end

      begin
        payload = JSON.parse(body)
        value = payload["value"]
        unless value.is_a?(Integer) && value.between?(0, 255)
          write_json(response, 400, "error" => "value must be an integer from 0 to 255") # gay ass lib2proc bit system
          next
        end

        worker = Thread.new(value) do |byte|
          memory = Memory.new(capacity: 1)
          address = memory.allocate(1)
          begin
            memory.write(address, [byte].pack("C"))
            {
              "value" => memory.read(address, length: 1).unpack1("C"),
              "worker_thread_id" => Thread.current.object_id
            }
          ensure
            memory.free(address)
          end
        end

        write_json(response, 200, worker.value)
      rescue JSON::ParserError
        write_json(response, 400, "error" => "invalid JSON")
      rescue StandardError
        write_json(response, 500, "error" => "worker failed")
      end
    end

    server
  end

  def self.write_json(response, status, payload)
    response.status = status
    response["Content-Type"] = "application/json"
    response.body = JSON.generate(payload)
  end
  private_class_method :write_json
end

if $PROGRAM_NAME == __FILE__
  MemoryService.build_server.start
end