class Imgproxy < Formula
  desc "Fast and secure server for resizing and converting remote images"
  homepage "https://imgproxy.net"
  url "https://github.com/imgproxy/imgproxy/archive/v2.16.3.tar.gz"
  sha256 "484de4e863bbaf4aafb52c581102a24c21b046722c94f382000fbd3e6a4db3bc"
  license "MIT"
  revision 1
  head "https://github.com/imgproxy/imgproxy.git"

  bottle do
    sha256 cellar: :any, arm64_big_sur: "d109776b1ca2b530587fdf70f31f5912bc09c80fb40ed5e2f648f3d60357c19d"
    sha256 cellar: :any, big_sur:       "92a509d0dbe16860c3d834a91d61349a754ee7196c0d0bfad3fad8c1b64cb561"
    sha256 cellar: :any, catalina:      "651e12c0f5b11ae980201ac91371c10a79a595a1ed6070fdb956f730dcb81bb0"
    sha256 cellar: :any, mojave:        "417f141d3140bf51e76f507a8c7669bec5243f0c80d1f4c6a30c6224d88bc532"
  end

  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "vips"

  # patch build, remove in next release
  patch do
    url "https://github.com/imgproxy/imgproxy/commit/488d786.patch?full_index=1"
    sha256 "4d1b3646c8b61883fe35bf9da37ce2f6e2e128643b4c22ba831d0bc9aa96c9dd"
  end

  def install
    ENV["CGO_LDFLAGS_ALLOW"]="-s|-w"
    ENV["CGO_CFLAGS_ALLOW"]="-Xpreprocessor"

    system "go", "build", *std_go_args
  end

  test do
    port = free_port

    cp(test_fixtures("test.jpg"), testpath/"test.jpg")

    ENV["IMGPROXY_BIND"] = "127.0.0.1:#{port}"
    ENV["IMGPROXY_LOCAL_FILESYSTEM_ROOT"] = testpath

    pid = fork do
      exec bin/"imgproxy"
    end
    sleep 10

    output = testpath/"test-converted.png"

    system "curl", "-s", "-o", output,
           "http://127.0.0.1:#{port}/insecure/fit/100/100/no/0/plain/local:///test.jpg@png"
    assert_equal 0, $CHILD_STATUS
    assert_predicate output, :exist?

    file_output = shell_output("file #{output}")
    assert_match "PNG image data", file_output
    assert_match "1 x 1", file_output
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
