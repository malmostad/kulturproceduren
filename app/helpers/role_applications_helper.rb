module RoleApplicationsHelper
  def state_string(application)
    case application.state
    when RoleApplication::PENDING then return "Inskickad"
    when RoleApplication::ACCEPTED then return "Godkänd"
    when RoleApplication::DENIED then return "Nekad"
    end
  end

  def type_string(application)
    case application.role.symbol_name
    when :booker then return "Bokning"
    when :culture_worker then return "Publicering"
    end
  end
end
