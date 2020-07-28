Puppet::Type.type(:desired_members).provide(:windows_adsi), :parent => :windows_adsi do

  desc "Local group management for Windows. Group members can be both users and groups.
        Additionally, local groups can contain domain users. Needed to supply provider
        for desired_members type"

end

