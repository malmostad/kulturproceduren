# -*- encoding : utf-8 -*-
module RoleApplicationsHelper
  # Converts a role application state into a string readable for humans.
  def state_string(application)
    case application.state
    when RoleApplication::PENDING then return "Inskickad"
    when RoleApplication::ACCEPTED then return "Godkänd"
    when RoleApplication::DENIED then return "Nekad"
    end
  end

  # Converts a role application role name to a string readable for humans.
  def type_string(application)
    case application.role.symbol_name
    when :booker then return "Bokning"
    when :host then return "Evenemangsvärd"
    when :culture_worker
      if application.culture_provider
        return "Publicering för #{html_escape(application.culture_provider.name)}"
      else
        return "Publicering för #{html_escape(application.new_culture_provider_name)}"
      end
    end
  end
end
