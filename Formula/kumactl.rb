class Kumactl < Formula
  desc "Kuma control plane command-line utility"
  homepage "https://kuma.io/"
  url "https://github.com/kumahq/kuma/archive/1.1.6.tar.gz"
  sha256 "946bc6d06d1fc2a0ab4bca431496134c3dab050fb7a85d6073273f918aed899a"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "16e1cd8d5a7ca22581cf369b433a34bde0340cbb8554ac4301ed91129349e190"
    sha256 cellar: :any_skip_relocation, big_sur:       "5e7e70a13d8271439c0492e56745d319c1b39d49251b43975c859a20f8f57d0c"
    sha256 cellar: :any_skip_relocation, catalina:      "bda6a4e45d7212b6b57e1cc37f29c72548168c23b4b350594c47c83b1812253e"
    sha256 cellar: :any_skip_relocation, mojave:        "40472bc58519021c64769eea1bb8bbdb846e39b3e01192547d96d8f5adf8be6b"
  end

  depends_on "go" => :build

  def install
    srcpath = buildpath/"src/kuma.io/kuma"
    srcpath.install buildpath.children

    cd srcpath do
      system "make", "build/kumactl", "BUILD_INFO_VERSION=#{version}"
      bin.install Dir["build/artifacts-*/kumactl/kumactl"].first
    end

    output = Utils.safe_popen_read("#{bin}/kumactl", "completion", "bash")
    (bash_completion/"kumactl").write output

    output = Utils.safe_popen_read("#{bin}/kumactl", "completion", "zsh")
    (zsh_completion/"_kumactl").write output

    output = Utils.safe_popen_read("#{bin}/kumactl", "completion", "fish")
    (fish_completion/"kumactl.fish").write output
  end

  test do
    assert_match "Management tool for Kuma.", shell_output("#{bin}/kumactl")
    assert_match version.to_s, shell_output("#{bin}/kumactl version 2>&1")

    touch testpath/"config.yml"
    assert_match "Error: no resource(s) passed to apply",
    shell_output("#{bin}/kumactl apply -f config.yml 2>&1", 1)
  end
end
