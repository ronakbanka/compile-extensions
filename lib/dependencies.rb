module CompileExtensions
  class Dependencies
    def initialize(manifest)
      @manifest = manifest
    end

    def find_matching_dependency(uri)
      mapping = find_dependency_mapping(uri)

      return nil if mapping.nil?

      find_dependency_with_mapping(mapping)
    end

    def find_translated_url(uri)
      dependency = find_matching_dependency(uri)

      return nil if dependency.nil?

      dependency['uri']
    end

    private

    def find_dependency_mapping(uri)
      @manifest['url_to_dependency_map'].find do |mapping|
        puts mapping['match']
        uri.match(mapping['match'])
      end
    end

    def find_dependency_with_mapping(mapping)
      @manifest['dependencies'].find do |dependency|
        dependency['version'] == mapping['version'] &&
            dependency['name'] == mapping['name']
      end
    end
  end
end
