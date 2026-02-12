class Sigil < Formula
  desc "Extract Apple system symbols as clean SVG vectors"
  homepage "https://github.com/dannolan/sigil"
  url "https://github.com/dannolan/sigil/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "f3c990f7e8f18e635fcedca46adc3f2e1a92ec62cde429c23279685fdf47cdcb"
  license "MIT"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/sigil"
  end

  test do
    assert_match "star.fill", shell_output("#{bin}/sigil --list")
  end
end
