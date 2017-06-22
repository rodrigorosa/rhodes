module RhoDevelopment

  class BuildServer

    def build_partial_bundles_for_all_subscribers(aFilename)
      Configuration::enabled_subscribers.each { |each|
        self.build_partial_bundle_for_platform(each.normalized_platform_name, aFilename)
      }
    end

    def build_partial_bundle_for_platform(aPlatform, aFilename)
      RhoDevelopment.setup(Configuration::development_directory, aPlatform)
      RhoDevelopment.make_partial_bundle
      self.copy_platform_bundle_to_web_server_root(aPlatform, Configuration::partial_bundle_name, aFilename)
    end

    def build_full_bundle_for_subscriber(aSubscriber, aFilename)
      RhoDevelopment.setup(Configuration::development_directory, aSubscriber.normalized_platform_name)
      RhoDevelopment.make_full_bundle
      self.copy_platform_bundle_to_web_server_root(aSubscriber.normalized_platform_name, Configuration::full_bundle_name, aFilename)
    end

    def build_full_bundles_for_all_subscribers(aFilename)
      Configuration::enabled_subscribers.each { |each|
        self.build_full_bundle_for_subscriber(each, aFilename)
      }
    end

    def copy_platform_bundle_to_web_server_root(platform, sourceFilename, targetFilename)
      case platform
        when 'iphone'
          tmp = 'iOS'
        when 'android'
          tmp = 'android'
        when 'wm'
          tmp = 'MC3000c50b (ARMV4I)'
        else
          tmp = platform
      end
      from = File.join(Configuration::application_root,'bin', 'target', tmp, sourceFilename)
      to = File.join(Configuration::document_root, 'download', platform, targetFilename)
      puts "Copy to #{to.to_s}".warning
      FileUtils.mkpath(File.dirname(to))
      FileUtils.cp(from, to)
    end

  end

end