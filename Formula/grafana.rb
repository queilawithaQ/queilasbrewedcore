class Grafana < Formula
  desc "Gorgeous metric visualizations and dashboards for timeseries databases"
  homepage "https://grafana.com"
  url "https://github.com/grafana/grafana/archive/v8.0.2.tar.gz"
  sha256 "2262c8ac65bc18e8bfb60cf7c363edf1911cf4a6a54722c27cd54a71c98ebb8b"
  license "AGPL-3.0-only"
  head "https://github.com/grafana/grafana.git"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "34646d03c1a24067962a07d12d86b9ed58da38b06fc2281b344ca7af5440e7cd"
    sha256 cellar: :any_skip_relocation, big_sur:       "4d0414ea29d73e1f4430d72c9897b35731f2043e4dee81e394e1a10cc0a8e808"
    sha256 cellar: :any_skip_relocation, catalina:      "5b85d1954014757ec61df7e90124bb8c946d8459bcd01853c0037adcad122697"
    sha256 cellar: :any_skip_relocation, mojave:        "38033d1ffff98e828f086287ef800dae2497bc0aa6b624a3be7df7d5a5112069"
  end

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "yarn" => :build

  uses_from_macos "zlib"

  on_linux do
    depends_on "fontconfig"
    depends_on "freetype"
  end

  def install
    system "go", "run", "build.go", "build"

    system "yarn", "install", "--ignore-engines", "--network-concurrency", "1"

    system "node_modules/webpack/bin/webpack.js", "--config", "scripts/webpack/webpack.prod.js"

    on_macos do
      bin.install Dir["bin/darwin-*/grafana-cli"]
      bin.install Dir["bin/darwin-*/grafana-server"]
    end
    on_linux do
      bin.install "bin/linux-amd64/grafana-cli"
      bin.install "bin/linux-amd64/grafana-server"
    end
    (etc/"grafana").mkpath
    cp("conf/sample.ini", "conf/grafana.ini.example")
    etc.install "conf/sample.ini" => "grafana/grafana.ini"
    etc.install "conf/grafana.ini.example" => "grafana/grafana.ini.example"
    pkgshare.install "conf", "public", "tools"
  end

  def post_install
    (var/"log/grafana").mkpath
    (var/"lib/grafana/plugins").mkpath
  end

  plist_options manual: "grafana-server --config=#{HOMEBREW_PREFIX}/etc/grafana/grafana.ini --homepath #{HOMEBREW_PREFIX}/share/grafana --packaging=brew cfg:default.paths.logs=#{HOMEBREW_PREFIX}/var/log/grafana cfg:default.paths.data=#{HOMEBREW_PREFIX}/var/lib/grafana cfg:default.paths.plugins=#{HOMEBREW_PREFIX}/var/lib/grafana/plugins"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <dict>
            <key>SuccessfulExit</key>
            <false/>
          </dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/grafana-server</string>
            <string>--config</string>
            <string>#{etc}/grafana/grafana.ini</string>
            <string>--homepath</string>
            <string>#{opt_pkgshare}</string>
            <string>--packaging=brew</string>
            <string>cfg:default.paths.logs=#{var}/log/grafana</string>
            <string>cfg:default.paths.data=#{var}/lib/grafana</string>
            <string>cfg:default.paths.plugins=#{var}/lib/grafana/plugins</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}/lib/grafana</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/grafana/grafana-stderr.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/grafana/grafana-stdout.log</string>
          <key>SoftResourceLimits</key>
          <dict>
            <key>NumberOfFiles</key>
            <integer>10240</integer>
          </dict>
        </dict>
      </plist>
    EOS
  end

  test do
    require "pty"
    require "timeout"

    # first test
    system bin/"grafana-server", "-v"

    # avoid stepping on anything that may be present in this directory
    tdir = File.join(Dir.pwd, "grafana-test")
    Dir.mkdir(tdir)
    logdir = File.join(tdir, "log")
    datadir = File.join(tdir, "data")
    plugdir = File.join(tdir, "plugins")
    [logdir, datadir, plugdir].each do |d|
      Dir.mkdir(d)
    end
    Dir.chdir(pkgshare)

    res = PTY.spawn(bin/"grafana-server",
      "cfg:default.paths.logs=#{logdir}",
      "cfg:default.paths.data=#{datadir}",
      "cfg:default.paths.plugins=#{plugdir}",
      "cfg:default.server.http_port=50100")
    r = res[0]
    w = res[1]
    pid = res[2]

    listening = Timeout.timeout(10) do
      li = false
      r.each do |l|
        if /HTTP Server Listen/.match?(l)
          li = true
          break
        end
      end
      li
    end

    Process.kill("TERM", pid)
    w.close
    r.close
    listening
  end
end
