module MembersHelper
  def edit_member_path_for(member)
    case member.role
    when "manager" then edit_member_manager_path(member)
    when "driver" then edit_member_driver_path(member)
    when "student" then edit_member_student_path(member)
    end
  end
end
