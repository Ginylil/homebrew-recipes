# frozen_string_literal: true

# fon — terminal learning agent. Remember, remember, the fifth of November.
# Installs signed release binary from fon.ginylil.com (same as fon_install.py).
class Fon < Formula
  desc "Terminal learning agent: PTY proxy, typo fix, error capture, IDE rules"
  homepage "https://fon.ginylil.com"
  url "https://fon.ginylil.com/releases/version"
  # Bump this when cutting releases so "brew install" shows the real version (e.g. 0.0.15).
  version "1.0.0"
  license "Apache-2.0"
  # Checksum omitted: version JSON changes each release; we download binary in install.
  sha256 :no_check

  livecheck do
    url "https://fon.ginylil.com/releases/version"
    strategy :page_match
    regex(/"version"\s*:\s*"v?([^"]+)"/)
  end

  # Skip bottle; we download the pre-built signed binary for this platform.
  pour_bottle? only_if: :default_prefix

  def install
    require "json"
    require "net/http"

    base = "https://fon.ginylil.com/releases"
    version_file = buildpath/"version"
    data = if version_file.exist?
      JSON.parse(File.read(version_file))
    else
      # Fallback: fetch version JSON (e.g. if cached filename differs).
      uri = URI("#{base}/version")
      resp = Net::HTTP.get_response(uri)
      raise "Could not fetch #{uri}" unless resp.is_a?(Net::HTTPSuccess)
      JSON.parse(resp.body)
    end
    platform_key = platform_key_for(Hardware::CPU.arm?, OS.mac?)
    path_rel = data[platform_key]
    raise "No binary for #{platform_key} in releases/version" if path_rel.nil? || path_rel.empty?

    binary_url = "#{base}/#{path_rel}"
    download_path = buildpath/File.basename(path_rel)
    curl_download binary_url, to: download_path
    bin.install download_path => "fon"
  end

  def platform_key_for(arm, mac)
    os = mac ? "darwin" : "linux"
    arch = arm ? "arm64" : "amd64"
    "#{os}-#{arch}"
  end

  def post_install
    # Add fon to IDE MCP configs and Cursor commands (same as fon_install.py --ide-only).
    script_url = "https://fon.ginylil.com/fon_install.py"
    script_path = buildpath/"fon_install.py"
    begin
      curl_download script_url, to: script_path
      env = ENV.to_h.merge("FON_BIN" => (bin/"fon").to_s)
      system(env, "python3", script_path.to_s, "--ide-only")
    rescue StandardError => e
      opoo "Could not add fon to IDE configs: #{e.message}. Run: curl -sSL #{script_url} | python3 - --ide-only"
    end
  end

  test do
    assert_match(/usage|fon/i, shell_output("#{bin}/fon --help 2>&1"))
  end
end
