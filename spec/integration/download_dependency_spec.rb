require 'spec_helper'

describe 'download_dependency' do

  let(:app_cache_dir) { Dir.mktmpdir }
  let(:buildpack_cache_dir) { Dir.mktmpdir }

  def run_translate
    Open3.capture3("#{buildpack_dir}/compile-extensions/bin/download_dependency #{original_url} #{install_path}")
  end

  context "when the dependency is not cached at all" do
    it "downloads the resource"
    it "puts the resource in the app_cache_dir"
  end

end
