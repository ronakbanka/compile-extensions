module CompileExtensions
  class Dependencies

    def initialize(manifest)
      @manifest = manifest
    end

    def find_matching_dependency(uri)
      mapping = find_url_to_dependency_mapping(uri)
      find_dependency_with_mapping(mapping)
    end

    def find_translated_url(uri)
      if dependency = find_matching_dependency(uri)
        dependency['uri']
      end
    end

    private

    def find_url_to_dependency_mapping(uri)
      @manifest['url_to_dependency_map'].find do |mapping|
        matches = uri.match(mapping['match'])
        next unless matches.length > 1

        new_mapping            = Hash.new
        new_mapping['name']    = extract_versions_from_matchdata(mapping['name'], matches)
        new_mapping['version'] = extract_versions_from_matchdata(mapping['version'], matches)
        new_mapping
      end
    end

    def find_dependency_with_mapping(mapping)
      return nil unless mapping

      @manifest['dependencies'].find do |dependency|
        dependency['version'].to_s == mapping['version'].to_s &&
          dependency['name'] == mapping['name'] &&
          dependency['cf_stacks'].include?(stack)
      end
    end

    def extract_versions_from_matchdata(mapping_value, matches)
      if mapping_value_matches = mapping_value.match(%r"\$d")
        matches[mapping_value_matches.first]
      else
        mapping_value
      end
    end

    def stack
      ENV['CF_STACK'] || 'lucid64'
    end
  end
end
