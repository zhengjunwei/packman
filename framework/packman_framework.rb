require "pty"
require "expect"

require "utils"
require "cli"
require "version_spec"
require "command_line"
require "config_manager"
require "run_manager"
require "system/os/os"
require "system/os/os_atom"
require "system/os/os_manager"
require "system/os/redhat"
require "system/os/fedora"
require "system/os/rhel"
require "system/os/centos"
require "system/os/debian"
require "system/os/ubuntu"
require "system/os/cygwin"
require "system/os/mac"
require "system/shell/env"
require "system/network_manager"
require "file/file_manager"
require "compiler/compiler_atom"
require "compiler/compiler"
require "compiler/gcc_compiler"
require "compiler/intel_compiler"
require "compiler/llvm_compiler"
require "compiler/pgi_compiler"
require "compiler/compiler_set"
require "compiler/compiler_manager"
require "command/config"
require "command/collect"
require "command/fix"
require "command/edit"
require "command/install"
require "command/remove"
require "command/switch"
require "command/mirror"
require "command/update"
require "command/upgrade"
require "command/report"
require "command/help"
require "command/start"
require "command/stop"
require "command/status"
require "package/package_atom"
require "package/package_dsl_helper"
require "package/package_group_helper"
require "package/package"
require "package/package_loader"
require "legacy/config_manager_legacy"
require "legacy/package_legacy"
require "ruby/ruby_helper"

PACKMAN::ConfigManager.init

# Handover delegated methods to hide the modules and classes that contain the methods from users.
def handover_delegated_methods root, father = nil
  father ||= root
  return if not (father.class == Class or father.class == Module)
  father.constants.each do |child_name|
    child = father.const_get child_name
    handover_delegated_methods root, child
    next if not child.respond_to? :delegated_methods
    child.delegated_methods.each do |method_name|
      args = []
      # TODO: This 'rescue' can be dismissed when 'NoMethodError' is solved.
      begin
        child.method(method_name).parameters.each do |p|
          case p.first
          when :req
            args << p.last
          when :rest
            args << "*#{p.last}"
          when :opt
            args << "#{p.last} = nil"
          end          
        end
      rescue NoMethodError => e
        PACKMAN.report_error "Failed to handover delegated method #{PACKMAN.red method_name} in #{PACKMAN.red child_name}!"
      end
      args = args.join(', ')
      root.class_eval <<-EOT
        def self.#{method_name} #{args}
          #{father}::#{child_name}.#{method_name} #{args.gsub(/ = nil/, '')}
        end
      EOT
    end
  end
end
handover_delegated_methods PACKMAN

# Until this moment, we can add packages directory to $LOAD_PATH. Because there
# may be occasions that the name of some package class is the same with the
# builtin Ruby object.
$LOAD_PATH << "#{ENV['PACKMAN_ROOT']}/packages"

PACKMAN::OsManager.init
PACKMAN::Shell::Env.init
PACKMAN::CommandLine.init
PACKMAN::CompilerManager.init

begin
  PACKMAN::ConfigManager.parse
rescue SyntaxError => e
  PACKMAN.report_error "Failed to parse #{PACKMAN.red PACKMAN::CommandLine.config_file}!\n#{e}"
end

if not PACKMAN::CommandLine.subcommand == :config
  PACKMAN::PackageLoader.init
end

PACKMAN::CommandLine.check_options

Kernel.trap('INT') do
  print "GOOD BYE!\n"
  pid_file = "#{ENV['PACKMAN_ROOT']}/.pid"
  PACKMAN.rm pid_file if File.exist? pid_file and PACKMAN::CommandLine.process_exclusive?
  exit
end

at_exit {
  if $!
    # Delete pid_file if exception is thrown.
    pid_file = "#{ENV['PACKMAN_ROOT']}/.pid"
    PACKMAN.rm pid_file if File.exist? pid_file and PACKMAN::CommandLine.process_exclusive?  
  end
}
