module TinyMCE
  # The base module we include into ActionController::Base
  module Base
    # When this module is included, extend it with the available class methods
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # The controller declaration to enable tiny_mce on certain actions.
      # Takes options hash, raw_options string, and any normal params you
      # can send to a before_filter (only, except etc)
      def uses_tiny_mce(options = {})
        filepath = File.join(RAILS_ROOT, 'config', 'tiny_mce.yml')
        config = begin YAML::load(IO.read(filepath)) rescue {} end
        
        tiny_mce_options = (options.delete(:options) || {}).reverse_merge config
        raw_tiny_mce_options = options.delete(:raw_options) || ''

        # If the tiny_mce plugins includes the spellchecker, then form a spellchecking path,
        # add it to the tiny_mce_options, and include the SpellChecking module
        if !tiny_mce_options[:plugins].blank? && tiny_mce_options[:plugins].include?('spellchecker')
          tiny_mce_options.reverse_merge!(:spellchecker_rpc_url => "/" + self.controller_name + "/spellchecker")
          self.class_eval do
            include TinyMCE::SpellChecker
          end
        end

        # Set instance vars in the current class
        proc = Proc.new do |c|
          c.instance_variable_set(:@tiny_mce_options, tiny_mce_options)
          c.instance_variable_set(:@raw_tiny_mce_options, raw_tiny_mce_options)
          c.instance_variable_set(:@uses_tiny_mce, true)
        end

        # Run the above proc before each page load this method is declared in
        before_filter(proc, options)
      end

    end

  end
end
