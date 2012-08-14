require "vagrant/action/builder"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      autoload :Boot, File.expand_path("../action/boot", __FILE__)
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckCreated, File.expand_path("../action/check_created", __FILE__)
      autoload :CheckPortCollisions, File.expand_path("../action/check_port_collisions", __FILE__)
      autoload :CheckRunning, File.expand_path("../action/check_running", __FILE__)
      autoload :CheckVirtualbox, File.expand_path("../action/check_virtualbox", __FILE__)
      autoload :CleanMachineFolder, File.expand_path("../action/clean_machine_folder", __FILE__)
      autoload :Created, File.expand_path("../action/created", __FILE__)
      autoload :Destroy, File.expand_path("../action/destroy", __FILE__)
      autoload :DestroyConfirm, File.expand_path("../action/destroy_confirm", __FILE__)
      autoload :DestroyUnusedNetworkInterfaces, File.expand_path("../action/destroy_unused_network_interfaces", __FILE__)
      autoload :DiscardState, File.expand_path("../action/discard_state", __FILE__)
      autoload :Halt, File.expand_path("../action/halt", __FILE__)
      autoload :MessageNotCreated, File.expand_path("../action/message_not_created", __FILE__)
      autoload :MessageWillNotDestroy, File.expand_path("../action/message_will_not_destroy", __FILE__)
      autoload :ProvisionerCleanup, File.expand_path("../action/provisioner_cleanup", __FILE__)
      autoload :PruneNFSExports, File.expand_path("../action/prune_nfs_exports", __FILE__)
      autoload :Resume, File.expand_path("../action/resume", __FILE__)
      autoload :Suspend, File.expand_path("../action/suspend", __FILE__)

      # Include the built-in modules so that we can use them as top-level
      # things.
      include Vagrant::Action::Builtin

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use Vagrant::Action::General::Validate
                b3.use CheckAccessible
                b3.use EnvSet, :force => true
                b3.use action_halt
                b3.use ProvisionerCleanup
                b3.use PruneNFSExports
                b3.use Destroy
                b3.use CleanMachineFolder
                b3.use DestroyUnusedNetworkInterfaces
              else
                b3.use MessageWillNotDestroy
              end
            end
          end
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible
              b2.use DiscardState
              b2.use Halt
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # This is the action that is primarily responsible for resuming
      # suspended machines.
      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible
              b2.use CheckPortCollisions
              b2.use Resume
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHRun
        end
      end

      # This is the action that is primarily responsible for suspending
      # the virtual machine.
      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible
              b2.use Suspend
            else
              b2.use MessageNotCreated
            end
          end
        end
      end
    end
  end
end
