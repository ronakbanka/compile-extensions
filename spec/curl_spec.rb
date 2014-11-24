require 'spec_helper'
require 'open3'
require 'tempfile'

describe 'curl' do
  attr :stdout, :stderr, :status

  CURL_CMD = File.join(File.dirname(__FILE__), '..', 'bin', 'curl')

  def curl argstring
    shell_out "#{CURL_CMD} #{argstring}"
  end

  def shell_out command
    @stdout, @stderr, @status = Open3.capture3 command
  end

  context 'when BUILDPACK_PATH is not set' do
    before { ENV.delete('BUILDPACK_PATH') }

    it 'emits a warning message' do
      curl 'http://files.com/file.txt'

      expect(stderr).to include('You are running a buildpack version of curl but have not set BUILDPACK_PATH')
    end

    it 'exits with non-zero status code' do
      curl 'http://files.com/file.txt'

      expect(status).to_not be_success
    end
  end

  context 'when BUILDPACK_PATH is set' do
    let(:buildpack_path) { '/tmp/common_spec' }

    before do
      ENV['BUILDPACK_PATH'] = buildpack_path
      FileUtils.mkdir_p buildpack_path
    end

    after do
      FileUtils.rm_rf buildpack_path
    end


    context 'the cache is empty' do
      it 'does not warn about BUILDPACK PATH' do
        curl 'http://files.com/file.txt'

        expect(stderr).to_not include('You are running a buildpack version of curl but have not set BUILDPACK_PATH')
      end

      it 'exits cleanly' do
        curl 'http://files.com/file.txt'

        expect(status).to be_success
      end

      it 'warns when the file is not in the cache' do
        expected_output='Resource http://files.com/file.txt is not provided by this buildpack. Please upgrade your buildpack to receive the latest resources.'

        curl 'http://files.com/file.txt'

        expect(stderr).to include(expected_output)
      end
    end

    context 'a file is in the cache' do
      let(:protocol) { 'http' }

      before do
        dep_dir = File.join(buildpack_path, 'dependencies')
        file_name = "#{protocol}___files.com_file.txt"
        cached_file = File.join(dep_dir, file_name)
        FileUtils.mkdir_p dep_dir
        File.open(cached_file, 'w') { |f| f.write 'some text' }
      end

      it 'there is no warning about the file not existing in the cache' do
        expected_output='Resource http://files.com/file.txt is not provided by this buildpack. Please upgrade your buildpack to receive the latest resources.'

        curl 'http://files.com/file.txt'

        expect(stderr).to_not include(expected_output)
      end


      it "grabs the cached file's contents" do
        curl "#{protocol}://files.com/file.txt"

        expect(stdout).to eq('some text')
      end

      context 'curl is invoked with output parameter' do
        context 'which is stdout' do
          it "grabs the cached file's contents" do
            curl "-o- #{protocol}://files.com/file.txt"

            expect(stdout).to eq('some text')
          end

          it "grabs the cached file's contents" do
            curl "#{protocol}://files.com/file.txt -o-"

            expect(stdout).to eq('some text')
          end

        end

        context 'which is another file' do
          it "grabs the cached file's contents" do
            filename = Tempfile.new('cache').path
            begin
              curl "-o #{filename} #{protocol}://files.com/file.txt"

              expect(File.read(filename)).to eq('some text')
            ensure
              FileUtils.rm filename
            end
          end
        end

        context 'which is the original file name' do
          it "puts the cached file's contents into a file in the PWD" do
            curl "-sO #{protocol}://files.com/file.txt"
            expect(File.read('file.txt')).to eq('some text')
            FileUtils.rm 'file.txt'
          end
        end

        context 'https' do
          let!(:protocol) { 'https' }

          it "grabs the file's contents" do
            curl 'https://files.com/file.txt'

            expect(stdout).to eq('some text')
          end
        end
      end
    end
  end
end
