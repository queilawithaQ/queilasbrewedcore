class Mpg123 < Formula
  desc "MP3 player for Linux and UNIX"
  homepage "https://www.mpg123.de/"
  url "https://www.mpg123.de/download/mpg123-1.28.0.tar.bz2"
  mirror "https://downloads.sourceforge.net/project/mpg123/mpg123/1.28.0/mpg123-1.28.0.tar.bz2"
  sha256 "e49466853685026da5d113dc7ff026b1b2ad0b57d78df693a446add9db88a7d5"
  license "LGPL-2.1-only"

  livecheck do
    url "https://www.mpg123.de/download/"
    regex(/href=.*?mpg123[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 arm64_big_sur: "31d68d9fd42fe67e17a4a19957011d94c6697c7f90f83f099d146cc2e8d6b582"
    sha256 big_sur:       "2f69c200c9303936e1b23dd125f1fcca5ad0ed1bf52add33c18c15db3d10efab"
    sha256 catalina:      "40b0e8c3860067a4cb370e36d0b63fcd2d01c0f1271b9d742aa10de90fde354a"
    sha256 mojave:        "9d18dc298dc59bf76075bbefdecb2a2c3351c604aaf0bc99d9238c36009db1b6"
  end

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --with-module-suffix=.so
    ]

    on_macos do
      args << "--with-default-audio=coreaudio"
    end

    args << if Hardware::CPU.arm?
      "--with-cpu=aarch64"
    else
      "--with-cpu=x86-64"
    end

    system "./configure", *args
    system "make", "install"
  end

  test do
    system bin/"mpg123", "--test", test_fixtures("test.mp3")
  end
end
