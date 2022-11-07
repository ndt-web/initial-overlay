# TODO: ....

def isLive
  
  dnsdn  = `dnsdomainname`
  return (dnsdn.include? "..")
end
def ensure_exists_admin(username, email, pwd)

  account = Account.find_local(username)
  if account.nil?

    pwd = SecureRandom.hex if pwd.nil?

    account = Account.new(username: username); role = UserRole.find_by(name: 'Admin');
    raise "No role !!!!!!!!!" if role.nil?

    user = User.new(email: email, password: pwd, agreement: true, approved: true, role_id: role.id, confirmed_at: Time.now.utc, bypass_invite_request_check: true)
    
    account.suspended_at = nil

    ActiveRecord::Base.transaction do
      account.save!; user.account = account  
      user.save! # validation failure? exception??

      Rails.logger.debug "created User+Acct #{username } #{email} #{pwd}"
       
    end
  end
end

# # #################################### ###############################################
NdtLogger = Logger.new("#{Rails.root}/log/ndt_site.app.log")
def NdtLog(s)
  logger.info s
  NdtLogger.info(s)
end

module AcctType
 
  TYPES = {
      adh: {code: 1, noun: "ADHD", descrip: "Attention Deficit (ADH / ADD) "},
      autist: {code: 2, noun: "Autistic", descrip: "Autistic (ASD / Aspie)"},
      audhd: {code: 3, noun: "AuDHD", descrip: "AuDHD (ASD and ADH together) "},
      othernd: {code: 4, noun: "Other", descrip: "Other ND (complex / mixed ND)"},
      ally: {code: 21, noun: "Ally", descrip: "A parent / relative / friend / neighbor "},
      academic: {code: 22, noun: "Academic", descrip: "Researcher / academic "},
      pro: {code: 23, noun: "Therapist", descrip: "Social worker / therapist "},
  }
   
  WEB_DESCRIP = { 1 => "ADHD / ADD" ,      2 => "Autistic" ,    3 => "AuDHD" ,
                  4 => "Other ND",
                  21 => "Ally / Relative" , 22 => "Researcher", 23 => "Therapist"
   }

  PUBLIC_SIGNUP = [ :adh, :autist, :audhd, :othernd, :ally]
  PRIVATE_SIGNUP = [:academic, :pro]
  NDTKEY = :ndtype_ndt
  # TODO: color; emoji; css; etc. 

  def self.remembered_selection( collection) #index
     result =  collection[NDTKEY]&.to_i || 0  #=Thread.current[:auth_saveParams]
  end
  def self.set_ndtype_in_account(account,params)
    #account = user.account
    stored_index = remembered_selection(params)     ##result =  params[NDTKEY]&.to_i || 0
    int_value = [PUBLIC_SIGNUP.length-1, stored_index].min
    code = TYPES[PUBLIC_SIGNUP[int_value]][:code]
    account.set_extfield('ndtype', code)
  end
end
###################################################
module NdtGlobals
  # could just make truly global
  def self.attribute_altered?(att, hashorig, hashnow)
    return false if hashorig[att].nil? && hashnow[att].nil?
    !(hashorig[att].to_s == hashnow[att].to_s)
  end
  def self.altered?(val1,val2)
    return false if val1.nil? && val2.nil?
    !(val1.to_s == val2.to_s)
  end
  def self.hash_diff(a, b) # multiple ways to do this
    a
        .reject { |k, v| b[k] == v }
        .merge!(b.reject { |k, _v| a.key?(k) })
  end
end

