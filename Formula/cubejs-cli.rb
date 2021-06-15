require "language/node"

class CubejsCli < Formula
  desc "Cube.js command-line interface"
  homepage "https://cube.dev/"
  url "https://registry.npmjs.org/cubejs-cli/-/cubejs-cli-0.27.32.tgz"
  sha256 "c92165f91b76cc1714d8ec537fee826dca8f52a1f4996f88fe4b6ca969006403"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "94f0134099e64daaa29bf30098ac2d5712ef6251ac6fc19d8114635b899f02d4"
    sha256 cellar: :any_skip_relocation, big_sur:       "1aa235fbf6f369929bfb89277598349061749f7e3b5f483eac104af7c9ece5b6"
    sha256 cellar: :any_skip_relocation, catalina:      "1aa235fbf6f369929bfb89277598349061749f7e3b5f483eac104af7c9ece5b6"
    sha256 cellar: :any_skip_relocation, mojave:        "1aa235fbf6f369929bfb89277598349061749f7e3b5f483eac104af7c9ece5b6"
  end

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cubejs --version")
    system "cubejs", "create", "hello-world", "-d", "postgres"
    assert_predicate testpath/"hello-world/schema/Orders.js", :exist?
  end
end
