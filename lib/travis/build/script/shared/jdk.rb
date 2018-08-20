module Travis
  module Build
    class Script
      module Jdk

        include Template

        def configure
          super
          return unless uses_jdk?

          jdk = config[:jdk].gsub(/\s/,'')

          return if jdk == 'default'

          sh.raw(install_jdk(jdk), echo: true, timing: true, fold: 'install_jdk')
        end

        def export
          super
          sh.export 'TRAVIS_JDK_VERSION', config[:jdk], echo: false if uses_jdk?
        end

        def setup
          super

          sh.if '-f build.gradle || -f build.gradle.kts' do
            sh.export 'TERM', 'dumb'
          end

          sh.if '"$TRAVIS_DIST" == precise || "$TRAVIS_DIST" == trusty' do
            sh.echo "Disabling Gradle daemon", ansi: :yellow
            sh.cmd 'mkdir -p ~/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties', echo: true, timing: false
          end

          correct_maven_repo
        end

        def announce
          super
          if uses_java?
            sh.cmd 'java -Xmx32m -version'
            sh.cmd 'javac -J-Xmx32m -version'
          end
        end

        def cache_slug
          return super unless uses_jdk?
          super << '--jdk-' << config[:jdk].to_s
        end

        private

          def uses_java?
            true
          end

          def uses_jdk?
            !!config[:jdk]
          end

          def install_jdk(jdk)
            template('jdk.sh',
                     jdk: jdk,
                     jdk_glob: jdk_glob(jdk),
                     app_host: app_host,
                     args: install_jdk_args(jdk),
                     cache_dir: cache_dir)
          end

          def paths
            [ '/usr/lib/jvm', '/usr/local/lib/jvm' ]
          end

          def jdk_glob(jdk)
            "{#{paths.join(',')}}/#{jdk}*"
          end

          def install_jdk_args(jdk)
            m = jdk.match(/(?<vendor>[a-z]+)-?(?<version>.+)?/)
            if m[:vendor].start_with? 'oracle'
              license = 'BCL'
            elsif m[:vendor].start_with? 'openjdk'
              license = 'GPL'
            else
              return false
            end
            "--feature #{m[:version]} --license #{license}"
          end

          def cache_dir
            "${TRAVIS_HOME}/.cache/install-jdk"
          end

          def correct_maven_repo
            old_repo = 'https://repository.apache.org/releases/'
            new_repo = 'https://repository.apache.org/content/repositories/releases/'
            sh.cmd "sed -i 's|#{old_repo}|#{new_repo}|g' ~/.m2/settings.xml", echo: false, assert: false, timing: false
          end
      end
    end
  end
end
