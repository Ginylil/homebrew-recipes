# frozen_string_literal: true

require "fileutils"
require "net/http"
require "open3"
require "tmpdir"
require "uri"
require "yaml"

# fon — terminal learning agent. Remember, remember, the fifth of November.
# Installs signed release binary from fon.ginylil.com (same as fon_install.py).
# Version and sha256 come from Formula/fon_versions.yaml (updated by CI).
class Fon < Formula
  desc "Terminal learning agent: PTY proxy, typo fix, error capture, IDE rules"
  homepage "https://fon.ginylil.com"

  FON_VERSIONS = YAML.load_file(File.join(File.dirname(__FILE__), "fon_versions.yaml"))
  FON_VERSION = FON_VERSIONS["latest"]
  FON_SHA256 = FON_VERSIONS["versions"][FON_VERSION]

  url "https://fon.ginylil.com/releases/#{FON_VERSION}/version"
  version FON_VERSION
  sha256 FON_SHA256
  license "Apache-2.0"

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
      # Fallback: fetch this version's JSON (releases/{version}/version).
      uri = URI("#{base}/#{version}/version")
      resp = Net::HTTP.get_response(uri)
      raise "Could not fetch #{uri}" unless resp.is_a?(Net::HTTPSuccess)
      JSON.parse(resp.body)
    end
    platform_key = platform_key_for(Hardware::CPU.arm?, OS.mac?)
    path_rel = data[platform_key]
    raise "No binary for #{platform_key} in releases/version" if path_rel.nil? || path_rel.empty?

    binary_url = "#{base}/#{path_rel}"
    download_path = buildpath/File.basename(path_rel)
    system "curl", "-fL", binary_url, "-o", download_path.to_s
    bin.install download_path => "fon"
    # Copy version YAML to Cellar .brew so post_install (loaded from Cellar) can find it.
    brew_dir = prefix/".brew"
    brew_dir.mkpath
    yaml_src = File.join(File.dirname(__FILE__), "fon_versions.yaml")
    FileUtils.cp(yaml_src, brew_dir/"fon_versions.yaml") if File.file?(yaml_src)
  end

  def platform_key_for(arm, mac)
    os = mac ? "darwin" : "linux"
    arch = arm ? "arm64" : "amd64"
    "#{os}-#{arch}"
  end

  def post_install
    script_url = "https://fon.ginylil.com/fon_install.py"
    fon_bin = (bin/"fon").to_s
    unless File.file?(fon_bin) && File.executable?(fon_bin)
      opoo "fon binary not found at #{fon_bin}; skipping IDE setup."
      return
    end

    ohai "To add fon to your IDE (MCP + Cursor commands), run:"
    puts "  curl -sSL #{script_url} | python3 - --ide-only"
    puts "Then reload Cursor Settings → MCP and use / in chat for commands."
    puts ""

    return unless $stdin.tty?

    print "Run this now? [Y/n] "
    answer = $stdin.gets&.strip&.downcase
    return if answer == "n" || answer == "no"

    # Run in-process (sandbox may block writes to ~/.cursor on macOS; then user runs command in their terminal).
    script_dir = Dir.mktmpdir("fon-postinstall")
    script_path = Pathname(script_dir).join("fon_install.py")
    begin
      uri = URI(script_url)
      resp = Net::HTTP.get_response(uri)
      unless resp.is_a?(Net::HTTPSuccess)
        opoo "Download failed: #{resp.code}. Run the command above in your terminal."
        return
      end
      script_path.write(resp.body)
    rescue StandardError => e
      opoo "Download failed: #{e.message}. Run the command above in your terminal."
      return
    end
    env = ENV.to_h.merge("FON_BIN" => fon_bin, "PATH" => "#{bin}:#{ENV["PATH"]}")
    out, err, status = Open3.capture3(env, "python3", script_path.to_s, "--ide-only")
    if status.success?
      ohai "IDE setup finished. Reload MCP in Cursor and use / in chat."
    else
      opoo "IDE setup failed (sandbox may block writes to ~/.cursor). Run the command above in your terminal."
      puts err.strip if err && !err.strip.empty?
    end
  end

  def caveats
    <<~EOS
      At the end of install you can run IDE setup to add fon to Cursor (MCP + slash commands).
      To run it later:
        curl -sSL https://fon.ginylil.com/fon_install.py | python3 - --ide-only
      Then reload Cursor Settings → MCP and use / in chat.
    EOS
  end

  test do
    assert_match(/usage|fon/i, shell_output("#{bin}/fon --help 2>&1"))
    version_out = shell_output("#{bin}/fon --version 2>&1")
    assert_match(/\d+\.\d+\.\d+/, version_out, "fon --version should print a semver")
  end
end
