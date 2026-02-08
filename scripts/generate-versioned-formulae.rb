#!/usr/bin/env ruby
# frozen_string_literal: true

# Reads Formula/fon_versions.yaml and writes Formula/fon@X.Y.Z.rb for each version.
# Run from repo root.

require "yaml"

FORMULA_DIR = File.join(File.dirname(__FILE__), "..", "Formula")
YAML_PATH = File.join(FORMULA_DIR, "fon_versions.yaml")

data = YAML.load_file(YAML_PATH)
versions = data["versions"] || {}

template = <<~RUBY
  # frozen_string_literal: true

  # fon %<ver>s — generated from Formula/fon_versions.yaml.
  class FonAT%<class_suffix>s < Formula
    desc "Terminal learning agent: PTY proxy, typo fix, error capture, IDE rules"
    homepage "https://fon.ginylil.com"
    url "https://fon.ginylil.com/releases/%<ver>s/version"
    version "%<ver>s"
    sha256 "%<sha>s"
    license "Apache-2.0"
    pour_bottle? only_if: :default_prefix

    def install
      require "json"
      require "net/http"
      base = "https://fon.ginylil.com/releases"
      version_file = buildpath/"version"
      data = if version_file.exist?
        JSON.parse(File.read(version_file))
      else
        uri = URI(\"\#{base}/\#{version}/version\")
        resp = Net::HTTP.get_response(uri)
        raise \"Could not fetch \#{uri}\" unless resp.is_a?(Net::HTTPSuccess)
        JSON.parse(resp.body)
      end
      platform_key = platform_key_for(Hardware::CPU.arm?, OS.mac?)
      path_rel = data[platform_key]
      raise \"No binary for \#{platform_key}\" if path_rel.nil? || path_rel.empty?
      binary_url = \"\#{base}/\#{path_rel}\"
      download_path = buildpath/File.basename(path_rel)
      system "curl", "-fL", binary_url, "-o", download_path.to_s
      bin.install download_path => "fon"
    end

    def platform_key_for(arm, mac)
      os = mac ? "darwin" : "linux"
      arch = arm ? "arm64" : "amd64"
      \"\#{os}-\#{arch}\"
    end

    def post_install
      script_url = "https://fon.ginylil.com/fon_install.py"
      script_path = buildpath/"fon_install.py"
      begin
        system "curl", "-fL", script_url, "-o", script_path.to_s
        env = ENV.to_h.merge("FON_BIN" => (bin/"fon").to_s)
        system(env, "python3", script_path.to_s, "--ide-only")
      rescue StandardError => e
        opoo \"Could not add fon to IDE configs: \#{e.message}\"
      end
    end

    test do
      assert_match(/usage|fon/i, shell_output(\"\#{bin}/fon --help 2>&1\"))
      assert_match(/\\d+\\.\\d+\\.\\d+/, shell_output(\"\#{bin}/fon --version 2>&1\"))
    end
  end
RUBY

versions.each do |ver, sha|
  class_suffix = ver.delete(".")
  out_path = File.join(FORMULA_DIR, "fon@#{ver}.rb")
  content = format(template, ver: ver, class_suffix: class_suffix, sha: sha)
  File.write(out_path, content)
  puts "Wrote #{out_path}"
end
