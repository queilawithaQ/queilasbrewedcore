class Caddy < Formula
  desc "Powerful, enterprise-ready, open source web server with automatic HTTPS"
  homepage "https://caddyserver.com/"
  url "https://github.com/caddyserver/caddy/archive/v2.4.2.tar.gz"
  sha256 "f6319d36f4e27a197c9aa832524a256ca9a9760f8334b52fbb6c618e63b22bf9"
  license "Apache-2.0"
  head "https://github.com/caddyserver/caddy.git"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "904dd347eb4ad0aca921385957412d746f9ece5c0f39deae05c32028065c0946"
    sha256 cellar: :any_skip_relocation, big_sur:       "7b2a8a292805f45b25b6046735182da667fa5eb5566acd9abecd2be3f41f23e8"
    sha256 cellar: :any_skip_relocation, catalina:      "7b2a8a292805f45b25b6046735182da667fa5eb5566acd9abecd2be3f41f23e8"
    sha256 cellar: :any_skip_relocation, mojave:        "7b2a8a292805f45b25b6046735182da667fa5eb5566acd9abecd2be3f41f23e8"
  end

  depends_on "go" => :build

  resource "xcaddy" do
    url "https://github.com/caddyserver/xcaddy/archive/v0.1.9.tar.gz"
    sha256 "399880f59bf093394088cf2d802b19e666377aea563b7ada5001624c489b62c9"
  end

  def install
    revision = build.head? ? version.commit : "v#{version}"

    resource("xcaddy").stage do
      system "go", "run", "cmd/xcaddy/main.go", "build", revision, "--output", bin/"caddy"
    end
  end

  plist_options manual: "caddy run --config #{HOMEBREW_PREFIX}/etc/Caddyfile"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <true/>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/caddy</string>
            <string>run</string>
            <string>--config</string>
            <string>#{etc}/Caddyfile</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>StandardOutPath</key>
          <string>#{var}/log/caddy.log</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/caddy.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    port1 = free_port
    port2 = free_port

    (testpath/"Caddyfile").write <<~EOS
      {
        admin 127.0.0.1:#{port1}
      }

      http://127.0.0.1:#{port2} {
        respond "Hello, Caddy!"
      }
    EOS

    fork do
      exec bin/"caddy", "run", "--config", testpath/"Caddyfile"
    end
    sleep 2

    assert_match "\":#{port2}\"",
      shell_output("curl -s http://127.0.0.1:#{port1}/config/apps/http/servers/srv0/listen/0")
    assert_match "Hello, Caddy!", shell_output("curl -s http://127.0.0.1:#{port2}")

    assert_match version.to_s, shell_output("#{bin}/caddy version")
  end
end
