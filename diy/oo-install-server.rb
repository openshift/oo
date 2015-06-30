#!/usr/bin/env ruby
require 'webrick'
include WEBrick

BIND_ADDRESS=ARGV[0]
DOCUMENT_ROOT=ARGV[1]
APP_URL=ARGV[2]

if APP_URL == 'oo-install.rhcloud.com'
  MAIN_SITE='install.openshift.com'
else
  MAIN_SITE=APP_URL
end

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

    # The tgz files are always served normally, curl is always served normally
    if using_curl or servable_path?(req.path)
      # Intercept directory requests
      if not req.path.end_with?('/') and File.directory?(DOCUMENT_ROOT + req.path)
        file_txt = []
        File.open(DOCUMENT_ROOT + "#{req.path}/index.html").each_line do |line|
          file_txt << line
        end
        res.content_type = 'text'
        res.body = file_txt.join("\n")
        raise WEBrick::HTTPStatus::OK
      elsif req.path.end_with?('.svg')
        res.content_type = 'image/svg+xml'
        res.body = site_logo
        raise WEBrick::HTTPStatus::OK
      else
        # Browsers are requesting gzip and deflate encoding.  All the files tgz
        # files are already compressed. If the Node proxy re-encodes it it will
        # break our tar instructions.  The filename will end in tgz but it will
        # really be wrapped with gzip.
        if ! req.header['accept-encoding'].empty?
          if req.path.end_with?('.tgz')
            res.header['content-encoding'] = "gzip"
          end
        end
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

  def site_logo
    @site_logo || begin
      text = ''
      File.open(DOCUMENT_ROOT + '/openshift-logo-horizontal-99a90035cbd613be7b6293335eb05563.svg', 'r') do |fh|
        fh.each_line{ |line| text << line }
      end
      text
    end
  end

  def servable_path?(path)
    @logger.info("PATH: #{path.inspect}")
    ['tgz','ico','css','svg'].each do |ext|
      next if not path.end_with?(".#{ext}")
      return true
    end
    return false
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
