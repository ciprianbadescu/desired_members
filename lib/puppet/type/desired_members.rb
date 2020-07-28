Puppet::Type.newtype(:desired_members) do
  @doc = "Change members of existing groups"

  desc "Add group member only if the username is a valid one"

  autorequire(:group) do
    self[:name]
  end

  newparam(:name) do
    desc "The name of the group."
    isnamevar
  end

  newparam(:auth_membership, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Configures the behavior of the `members` parameter.

      * `false` (default) --- The provided list of group members is partial,
        and Puppet **ignores** any members that aren't listed there.
      * `true` --- The provided list of of group members is comprehensive, and
        Puppet **purges** any members that aren't listed there."
    defaultto false
  end
  
  newproperty(:members, :array_matching => :all) do
    desc "The members of the group. For platforms or directory services where group
      membership is stored in the group objects, not the users. This parameter's
      behavior can be configured with `auth_membership`. If a member is not found
      it will be silently ignored"

    def change_to_s(currentvalue, newvalue)
      newvalue = actual_should(currentvalue, newvalue)

      currentvalue = currentvalue.join(",") if currentvalue != :absent
      newvalue = newvalue.join(",")
      super(currentvalue, newvalue)
    end

    def is_to_s(currentvalue)
      if provider.respond_to?(:members_to_s)
        currentvalue = '' if currentvalue.nil?
        currentvalue = currentvalue.is_a?(Array) ? currentvalue : currentvalue.split(',')

        return provider.members_to_s(currentvalue)
      end
      super(currentvalue)
    end

    def should_to_s(newvalue)
      is_to_s(actual_should(retrieve, newvalue))
    end

    # Calculates the actual should value given the current and
    # new values. This is only used in should_to_s and change_to_s
    # to fix the change notification issue reported in PUP-6542.
    def actual_should(currentvalue, newvalue)
      currentvalue = munge_members_value(currentvalue)
      newvalue = munge_members_value(newvalue)

      if @resource[:auth_membership]
        newvalue.uniq.sort 
      else
        (currentvalue + newvalue).uniq.sort
      end
    end

    # Useful helper to handle the possible property value types that we can
    # both pass-in and return. It munges the value into an array
    def munge_members_value(value)
      return [] if value == :absent
      return value.split(',') if value.is_a?(String)

      value
    end

    
    def insync?(current)
      if provider.respond_to?(:members_insync?)
        return provider.members_insync?(current, @should)
      end

      super(current)
    end

    # skip members that are not valid
    munge do |member|
      if provider.respond_to?(:member_valid?)
        if provider.member_valid?(member)
          member
        end
      end
    end
  end
end
