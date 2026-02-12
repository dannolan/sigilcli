class Sigilcli < Formula
  desc "Extract Apple system symbols as clean SVG vectors"
  homepage "https://github.com/dannolan/sigilcli"
  url "https://github.com/dannolan/sigilcli/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "65ed49a01453d4f482b7ab625e27954edefbe5b669186d2cbf35277386f65152"
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
