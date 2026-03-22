# frozen_string_literal: true

require "net/http"
require "open3"
require "uri"
require "yaml"

# fon — terminal learning agent. Remember, remember, the fifth of November.
# Installs signed release binary from fon.ginylil.com (same as fon_install.py).
# Version and sha256 come from Formula/fon_versions.yaml (updated by CI).
class Fon < Formula
  desc "Terminal learning agent: PTY proxy, typo fix, error capture, IDE rules"
  homepage "https://fon.ginylil.com"
  THIRD_PARTY_NOTICES_FILENAME = "THIRD_PARTY_NOTICES.txt"

  FON_VERSIONS = YAML.load_file(File.join(File.dirname(__FILE__), "fon_versions.yaml")).freeze
  FON_VERSION = FON_VERSIONS["latest"].freeze
  FON_SHA256 = FON_VERSIONS["versions"][FON_VERSION].freeze

  # Identifies downloads from this formula in CDN logs / Telegram (vs bare curl or browser).
  CURL_USER_AGENT = "Homebrew-fon/#{FON_VERSION} (formula=ginylil/recipes/fon; +https://github.com/ginylil/homebrew-recipes)".freeze

  url "https://fon.ginylil.com/releases/#{FON_VERSION}/version"
  sha256 FON_SHA256
  license "Apache-2.0"

  livecheck do
    url "https://fon.ginylil.com/releases/version"
    strategy :page_match
    regex(/"version"\s*:\s*"v?([^"]+)"/i)
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
    raise "No binary for #{platform_key} in releases/version" if path_rel.blank?

    binary_url = "#{base}/#{path_rel}"
    download_path = buildpath/File.basename(path_rel)
    system "curl", "-fL", "-A", CURL_USER_AGENT, binary_url, "-o", download_path.to_s
    bin.install download_path => "fon"

    notices_url = "#{base}/#{version}/#{THIRD_PARTY_NOTICES_FILENAME}"
    notices_path = buildpath/THIRD_PARTY_NOTICES_FILENAME
    system "curl", "-fL", "-A", CURL_USER_AGENT, notices_url, "-o", notices_path.to_s
    pkgshare.install notices_path

    # Copy version YAML to Cellar .brew for reference.
    brew_dir = prefix/".brew"
    brew_dir.mkpath
    yaml_src = File.join(File.dirname(__FILE__), "fon_versions.yaml")
    cp yaml_src, brew_dir/"fon_versions.yaml" if File.file?(yaml_src)
  end

  def post_install
    n = kill_managed_fon_processes
    return unless n.positive?

    noun = (n == 1) ? "process" : "processes"
    ohai "Stopped #{n} running fon web/mcp #{noun}."
    puts "Restart MCP in your IDE (and `fon web` if you use it) so they use the new binary."
  end

  def platform_key_for(arm, mac)
    os = mac ? "darwin" : "linux"
    arch = arm ? "arm64" : "amd64"
    "#{os}-#{arch}"
  end

  def caveats
    <<~EOS
      Next steps:
        fon web --open

      Terminal alternative:
        fon add-to-ide --list
        fon add-to-ide --enable cursor

      If the IDE still shows an old fon version:
        check its MCP config command path points to Homebrew's fon
        not ~/.local/fon/bin/fon or another stale path

      Third-party notices installed by Homebrew:
        #{opt_pkgshare}/#{THIRD_PARTY_NOTICES_FILENAME}
    EOS
  end

  test do
    assert_match(/usage|fon/i, shell_output("#{bin}/fon --help 2>&1"))
    version_out = shell_output("#{bin}/fon --version 2>&1")
    assert_match(/\d+\.\d+\.\d+/, version_out, "fon --version should print a semver")
    assert_path_exists pkgshare/THIRD_PARTY_NOTICES_FILENAME
  end

  private

  # Match go/internal/fonprocess (fon web / fon mcp only; not PTY fon shells).
  # Returns count of processes we successfully signaled (for user messaging in post_install).
  def kill_managed_fon_processes
    stdout, _stderr, status = Open3.capture3("ps", "-axo", "pid=,comm=,args=")
    return 0 unless status.success?

    killed = 0
    seen = {}
    stdout.each_line do |line|
      fields = line.split
      next if fields.length < 4

      pid = fields[0].to_i
      next if pid <= 0 || pid == Process.pid
      next if seen[pid]

      next unless fon_ps_comm?(fields[1])
      next unless managed_fon_subcommand?(fields[3])

      seen[pid] = true
      begin
        Process.kill("TERM", pid)
        killed += 1
      rescue Errno::ESRCH, Errno::EPERM
        # Ignore missing or forbidden PIDs.
      end
    end

    sleep 1 if killed.positive?
    killed
  end

  def fon_ps_comm?(command)
    command = command.to_s.strip
    command == "fon" || command == "fon.real" ||
      command.end_with?("/fon") || command.end_with?("/fon.real")
  end

  def managed_fon_subcommand?(arg)
    %w[web mcp].include?(arg.to_s.strip)
  end
end
