#!/usr/bin/env ruby
require 'webrick'
include WEBrick

BIND_ADDRESS=ARGV[0]
DOCUMENT_ROOT=ARGV[1]
MAIN_SITE='install.openshift.com'

@config = {
  :Port => 8080,
  :BindAddress => BIND_ADDRESS,
  :DocumentRoot => DOCUMENT_ROOT,
}

class InstallerServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req,res)
    using_curl = req.header['user-agent'].select{ |agent| agent.match(/^curl/) }.length > 0

    # Intercept traffic for redirect
    if not req.host == MAIN_SITE or not is_https?(req)
      if using_curl
        res.body = "#!/bin/sh\necho '\nThanks for your interest in OpenShift!\n\noo-install has moved on up to https://#{MAIN_SITE}/\nTo proceed, rerun your command as:\n\n\tsh <(curl -s https://#{MAIN_SITE}#{req.path})\n'; exit\n"
        raise WEBrick::HTTPStatus::OK
      else
        res.set_redirect(WEBrick::HTTPStatus[301], "https://#{MAIN_SITE}#{req.path}")
      end
    end

    # The zip files are always served normally, curl is always served normally
    if using_curl or req.path.end_with?('.zip') or req.path.end_with?('.ico') or req.path.end_with?('.css')
      # Intercept directory requests
      if not req.path.end_with?('/') and File.directory?(DOCUMENT_ROOT + req.path)
        file_txt = []
        File.open(DOCUMENT_ROOT + "#{req.path}/index.html").each_line do |line|
          file_txt << line
        end
        res.content_type = 'text'
        res.body = file_txt.join("\n")
        raise WEBrick::HTTPStatus::OK
      else
        file_handler.do_GET(req,res)
      end
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

  def is_https?(req)
    req.request_uri.scheme == 'https' or (req.header.has_key?('x-forwarded-proto') and req.header['x-forwarded-proto'].select{ |proto| proto == 'https' }.length > 0)
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
