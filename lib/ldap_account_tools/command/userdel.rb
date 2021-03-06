# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/error'

module LdapAccountManage
  module UserDel
    module_function

    def userdel(username, _options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      unless ldap.user_exists_by_name?(username)
        raise Util::ToolOperationError, "No such an user exists: #{username}"
      end

      injector.lock.account_modify_lock do
        ldap.userdel(username)
        ldap.groupdel(username)

        ldap.groups_from_member(username) do |entry|
          groupname = entry.cn[0]

          member_uid = ldap.member_in_group(groupname)
            .reject { |member| member == username }

          ldap.groupmod(
            groupname,
            replace: {
              memberUid: member_uid,
            },
          )
        end
      end
    end
  end

  class Command
    desc 'userdel [options] USER', 'delete an user from LDAP'
    def userdel(username)
      UserDel.userdel(username, options, @injector, @config)
    end
  end
end
