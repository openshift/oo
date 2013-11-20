#!/usr/bin/env ruby
require 'webrick'
include WEBrick

BIND_ADDRESS=ARGV[0]
DOCUMENT_ROOT=ARGV[1]

@config = {
  :Port => 8080,
  :BindAddress => BIND_ADDRESS,
  :DocumentRoot => DOCUMENT_ROOT,
}

class InstallerServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req,res)
    # The zip files are always served normally, curl is always served normally
    if req.path.end_with?('.zip') or req.path.end_with?('.ico') or req.header['user-agent'].select{ |agent| agent.match(/^curl/) }.length > 0
      file_handler.do_GET(req,res)
    else
      res.content_type = 'text/html'
      res.body = site_info
      raise WEBrick::HTTPStatus::OK
    end
  end

  def file_handler
    @file_handler || WEBrick::HTTPServlet::FileHandler.new(@server, DOCUMENT_ROOT)
  end

  def site_info
    @site_info || begin
      text = ''
      File.open(DOCUMENT_ROOT + '/site_info.html', 'r') do |fh|
        fh.each_line{ |line| text << line }
      end
      text
    end
  end

  alias :do_POST :do_GET
end

def start_webrick
  @server = WEBrick::HTTPServer.new(@config)
  yield @server if block_given?
  ['INT', 'TERM'].each { |signal| trap(signal) { @server.shutdown } }
  @server.start
end

start_webrick { |server| server.mount('/', InstallerServlet) }
