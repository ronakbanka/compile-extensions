require 'spec_helper'
require 'open3'

describe 'translate_dependency_url' do
  let(:buildpack_dir) { Dir.mktmpdir }

  let(:manifest) {
    <<-MANIFEST
---
url_to_dependency_map:
  -
    match: \/(ruby)-(\\d+\\.\\d+\\.\\d+).tgz
    version: $2
    name: $1
  -
    match: !ruby/regexp /\/jruby_(\\d+\\.\\d+\\.\\d+)_jdk_(\\d+\\.\\d+\\.\\d+).tgz/
    version: $1::$2
    name: jruby

dependencies:
  -
    name: ruby
    version: 1.9.3
    uri: http://thong.co.nz/file.tgz
    md5: #{Digest::MD5.hexdigest('')}
    cf_stacks:
      - lucid64
  -
    name: ruby
    version: 2.1.1
    uri: http://some.other.repo/ruby-two-one-one.tgz
    cf_stacks:
      - lucid64
  -
    name: jruby
    version: 1.9.3::1.7.0
    uri: http://another.repo/jruby_1.9.3_jdk_1.7.0.tgz
    cf_stacks:
      - lucid64
    MANIFEST
  }

  before do
    File.open(File.join(buildpack_dir, 'manifest.yml'), 'w') do |file|
      file.puts manifest
    end
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    `cd #{buildpack_dir} && cp -r #{base_dir} compile-extensions`
  end

  after do
    FileUtils.remove_entry buildpack_dir
  end

  context 'with a buildpack cache' do
    def run_translate
      Open3.capture3("#{buildpack_dir}/compile-extensions/bin/translate_dependency_url #{original_url}")
    end

    context 'when the url is defined in the manifest' do
      let(:original_url) { 'http://some.repo/ruby-1.9.3.tgz' }

      before do
        `mkdir #{buildpack_dir}/dependencies`
      end

      specify do
        translated_url, stderr, _ = run_translate

        expect(translated_url).to eq("file://#{buildpack_dir}/dependencies/http___thong.co.nz_file.tgz\n")
      end
    end
  end

  context 'without a buildpack cache' do
    def run_translate
      Open3.capture3("#{buildpack_dir}/compile-extensions/bin/translate_dependency_url #{original_url}")
    end

    context 'the url has a matcher in the manifest' do
      context 'ruby 1.9.3' do
        let(:original_url) { 'http://some.repo/ruby-1.9.3.tgz' }

        specify do
          translated_url, stderr, _ = run_translate

          expect(translated_url).to eq "http://thong.co.nz/file.tgz\n"
        end
      end

      context 'ruby 2.1.1' do
        let(:original_url) { 'https://original.com/ruby-2.1.1.tgz' }

        specify do
          translated_url, _, _ = run_translate

          expect(translated_url).to eq "http://some.other.repo/ruby-two-one-one.tgz\n"
        end
      end

      context 'jruby 1.9.3::1.7.0' do
        let(:original_url) { 'https://original.com/jruby_1.9.3_jdk_1.7.0.tgz' }

        specify do
          translated_url, _, _ = run_translate

          expect(translated_url).to eq "http://another.repo/jruby_1.9.3_jdk_1.7.0.tgz\n"
        end
      end

    end

    context 'the url does not have a matcher in the manifest' do
      let(:original_url) { 'http://i_r.not/here' }

      specify do
        translated_url, _, status = run_translate

        expect(translated_url).to eq "DEPENDENCY_MISSING_IN_MANIFEST: #{original_url}\n"
        expect(status).not_to be_success
      end
    end
  end

  context 'with an app cache' do
    let(:app_cache_dir) { Dir.mktmpdir }

    def run_translate
      Open3.capture3("#{buildpack_dir}/compile-extensions/bin/translate_dependency_url #{original_url} #{app_cache_dir}")
    end

    context 'with the resource already cached' do
      let(:original_url) { 'http://some.repo/ruby-1.9.3.tgz' }

      def create_app_cache_resource
        FileUtils.touch File.join(app_cache_dir, 'http___thong.co.nz_file.tgz')
      end

      def modify_app_cache_resource
        File.write(File.join(app_cache_dir, 'http___thong.co.nz_file.tgz'), 'ponies')
      end

      it 'returns the app cache file:// URI' do
        create_app_cache_resource

        translated_url, stderr, _ = run_translate
        expect(translated_url).to eq "file://#{app_cache_dir}/http___thong.co.nz_file.tgz\n"
      end

      context 'when the requested resource has a different MD5' do
        it 'returns does not return the app cache file:// URI' do
          create_app_cache_resource
          modify_app_cache_resource

          translated_url, stderr, _ = run_translate
          expect(translated_url).not_to eq "file://#{app_cache_dir}/http___thong.co.nz_file.tgz\n"
        end
      end
    end

    context 'with the resource not cached' do
      let(:original_url) { 'http://some.other.repo/ruby-9.9.9.tgz' }

      it 'returns does not return the app cache file:// URI' do
        translated_url, stderr, _ = run_translate
        expect(translated_url).not_to eq "file://#{app_cache_dir}/http___thong.co.nz_file.tgz\n"
      end
    end
  end
end
