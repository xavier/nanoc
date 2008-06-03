module Nanoc

  # A Nanoc::Site is the in-memory representation of a nanoc site. It holds
  # references to the following site data:
  #
  # * +pages+ is a list of Nanoc::Page instances representing pages
  # * +page_defaults+ is a Nanoc::PageDefaults instance representing page
  #   defaults
  # * +layouts+ is a list of Nanoc::Layout instances representing layouts
  # * +templates+ is a list of Nanoc::Template representing templates
  # * +code+ is a Nanoc::Code instance representing custom site code
  #
  # In addition, each site has a +config+ hash which stores the site
  # configuration. This configuration hash can have the following keys:
  #
  # +output_dir+:: The directory to which compiled pages will be written. This
  #                path is relative to the current working directory, but can
  #                also be an absolute path.
  #
  # +data_source+:: The identifier of the data source that will be used for
  #                 loading site data.
  #
  # +router+:: The identifier of the router that will be used for determining
  #            page paths.
  #
  # A site also has several helper classes:
  #
  # * +router+ is a Nanoc::Router subclass instance used for determining page
  #   paths.
  # * +data_source+ is a Nanoc::DataSource subclass instance used for managing
  #   site data.
  # * +compiler+ is a Nanoc::Compiler instance that turns pages into compiled
  #   pages.
  #
  # The physical representation of a Nanoc::Site is usually a directory that
  # contains a configuration file, site data, and some rake tasks. However,
  # different frontends may store data differently. For example, a web-based
  # frontend would probably store the configuration and the site content in a
  # database, and would not have rake tasks at all.
  class Site

    # The default configuration for a site. A site's configuration overrides
    # these options: when a Nanoc::Site is created with a configuration that
    # lacks some options, the default value will be taken from
    # +DEFAULT_CONFIG+.
    DEFAULT_CONFIG = {
      :output_dir       => 'output',
      :data_source      => 'filesystem',
      :router           => 'default',
      :index_filenames  => [ 'index.html' ]
    }

    attr_reader :config
    attr_reader :compiler, :data_source, :router
    attr_reader :pages, :page_defaults, :layouts, :templates, :code

    # Returns a Nanoc::Site object for the site specified by the given
    # configuration hash +config+.
    #
    # +config+:: A hash containing the site configuration.
    def initialize(config)
      # Load configuration
      @config = DEFAULT_CONFIG.merge(config.clean)

      # Create data source
      @data_source_class = PluginManager.instance.data_source(@config[:data_source].to_sym)
      raise Nanoc::Errors::UnknownDataSourceError.new(@config[:data_source]) if @data_source_class.nil?
      @data_source = @data_source_class.new(self)

      # Create compiler
      @compiler = Compiler.new(self)

      # Load code (necessary for custom routers)
      load_code

      # Create router
      @router_class = PluginManager.instance.router(@config[:router].to_sym)
      raise Nanoc::Errors::UnknownRouterError.new(@config[:router]) if @router_class.nil?
      @router = @router_class.new(self)

      # Initialize data
      @pages              = []
      @layouts            = []
      @templates          = []
      @page_defaults      = PageDefaults.new({})
      @page_defaults.site = self

      # Set not loaded
      @code_loaded = false
      @data_loaded = false
    end

    # Loads the custom site code. This method will be called as soon as the
    # Nanoc::Site instance is created (because the custom site code could
    # contain the definition of a custom router). It is not necessary to
    # explicitly call this method.
    def load_code(force=false)
      # Don't load code twice
      return if @code_loaded and !force

      @data_source.loading do
        # Get code
        @code = @data_source.code
        if @code.is_a? String
          warn(
            "In nanoc 2.1, DataSource#code should return a Code object. Future versions will not support these outdated data sources.",
            'DEPRECATION WARNING'
          )
          @code = Code.new(code)
        end
        @code.site = self

        # Execute code
        # FIXME move responsibility for loading site code elsewhere, so
        # potentially dangerous code can be put in a sandbox.
        @code.load
      end

      # Set loaded
      @code_loaded = true
    end

    # Loads the site data. This will query the Nanoc::DataSource associated
    # with the site and fetch all site data. The site data is cached, so
    # calling this method will not have any effect the second time, unless
    # +force+ is true.
    #
    # +force+:: If true, will force load the site data even if it has been
    #           loaded before, to circumvent caching issues.
    def load_data(force=false)
      # Don't load data twice
      return if @data_loaded and !force

      # Load code
      load_code(force)

      # Load data
      @data_source.loading do
        # Pages
        @pages = @data_source.pages
        if @pages.any? { |p| p.is_a? Hash }
          warn(
            "In nanoc 2.1, DataSource#pages should return an array of Nanoc::Page objects. Future versions will not support these outdated data sources.",
            'DEPRECATION WARNING'
          )
          @pages.map! { |p| Page.new(p[:uncompiled_content], p, p[:path]) }
        end
        @pages.each { |p| p.site = self }

        # Page defaults
        @page_defaults = @data_source.page_defaults
        if @page_defaults.is_a? Hash
          warn(
            "In nanoc 2.1, DataSource#page_defaults should return a Nanoc::PageDefaults object. Future versions will not support these outdated data sources.",
            'DEPRECATION WARNING'
          )
          @page_defaults = PageDefaults.new(@page_defaults)
        end
        @page_defaults.site = self

        # Layouts
        @layouts = @data_source.layouts
        if @layouts.any? { |l| l.is_a? Hash }
          warn(
            "In nanoc 2.1, DataSource#layouts should return an array of Nanoc::Layout objects. Future versions will not support these outdated data sources.",
            'DEPRECATION WARNING'
          )
          @layouts.map! { |l| Layout.new(l[:content], l, l[:path] || l[:name]) }
        end
        @layouts.each { |l| l.site = self }

        # Templates
        @templates = @data_source.templates
        if @templates.any? { |t| t.is_a? Hash }
          warn(
            "In nanoc 2.1, DataSource#templates should return an array of Nanoc::Template objects. Future versions will not support these outdated data sources.",
            'DEPRECATION WARNING'
          )
          @templates.map! { |t| Template.new(t[:content], t[:meta].is_a?(String) ? YAML.load(t[:meta]) : t[:meta], t[:name]) }
        end
        @templates.each { |t| t.site = self }
      end

      # Setup child-parent links
      @pages.each do |page|
        # Get parent
        parent_path = page.path.sub(/[^\/]+\/$/, '')
        parent = @pages.find { |p| p.path == parent_path }
        next if parent.nil? or page.path == '/'

        # Link
        page.parent = parent
        parent.children << page
      end

      # Set loaded
      @data_loaded = true
    end

  end

end
