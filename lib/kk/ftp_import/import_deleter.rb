require "kk/ftp_import/base"

class KK::FTP_Import::ImportDeleter

  #Should not be used anymore...

  def mark_for_delete()
    #District.where(extens_id: nil).update_all(to_delete: true)
    #School.where(extens_id: nil).update_all(to_delete: true)
    #AgeGroup.where(extens_id: nil).update_all(to_delete: true)
  end

  def delete_marked()
    #AgeGroup.delete_all(to_delete: true)
    #School.delete_all(to_delete: true)
    #District.delete_all(to_delete: true)
  end
end
