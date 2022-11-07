
############################################################
class User < ApplicationRecord  # only User has : belongs_to :account, inverse_of: :user
  attr_accessor :signup # super brief bridge in Devise ie, resource.signup = params
  has_many :ndt_pages

  def validate_email_dns?
    not   ....................... \
        && email_changed? && !external? && !(Rails.env.test? || Rails.env.development?)
  end
end
#########################################################
class Account < ApplicationRecord
   
  attribute :twitterusername, :string  #, default: -> {nil}
  
  def extfield_update_if_changed(attrib, newval)
    val = get_extfield(attrib)
    changed =  (val != newval)   # NdtGlobals.altered?( val, newval )

    if changed then
      set_extfield(attrib, newval)
      self.update!(:extfields => self[:extfields] ) # ??
      NdtLog("model updated ext new = " + self[:extfields].inspect )
    end
    changed
  end
  def some_recent_daybook_posts
    # by user id (smartly or dumbly)

    userid = user.id ; # db query now ?
    return nil if userid.nil?

    result = NdtPages.order(for_day: :desc).where(["user_id=? ", userid]).select("id,for_day").limit(15)
    result
  end

  def acct_type_descrip

    typecode = extfields['ndtype'] unless extfields.nil?
    #NdtLog("typecode #{typecode}")
    return nil if typecode.nil?

    typecode = typecode.to_i
    # what if out of range ? not found?
    descrip = (AcctType::WEB_DESCRIP[typecode])  # !AcctType::WEB_DESCRIP.has_key?(typecode)

  end
  #  If you are using structured database data types (e.g. PostgreSQL hstore/json, or MySQL 5.7+ json) there is no need for the serialization provided by .store. Simply use .store_accessor instead to generate the accessor methods. Be aware that
  # these columns use a string keyed hash and do not allow access using a symbol.
  def set_extfield(key,value)
    raise "Bad key" if key.nil?
    key = key.to_s
    tmp=(self[:extfields] || {})
    changed = !tmp.has_key?(key) # first set event?
    changed ||= (tmp[key] != value )

    self[:extfields] = tmp.merge(key => value )
    changed
  end
  def get_extfield(key)
    #if self[:extfields].nil? || !self[:extfields].has_key?(key) then return nil end
    raise "Bad key" if key.nil?
    key = key.to_s # this or hashWithIndiff
    return nil if self[:extfields].nil?
    tmp = (self[:extfields] || {})
    tmp[key ] #self[:extfields[key]]
  end

end

#################################################################################
class ApplicationController
  rescue_from StandardError do |e|
    #render json: {error: e}, status: 500; logger.error(e); raise e
    msg = (["#{self.class} - #{e.class}: #{e.message}"]+e.backtrace.take(6)).join("\n\n")
    logger.error(msg); NdtLog(msg ); # works
    render json: {error: msg}, status: 500; #logger.error(e); raise e
  end
end

# https://github.com/heartcombo/devise#strong-parameters
class Auth::RegistrationsController < Devise::RegistrationsController

  rescue_from StandardError do |e|
    #render json: {error: e}, status: 500; logger.error(e); raise e
    msg = (["#{self.class} - #{e.class}: #{e.message}"]+e.backtrace).join("\n")
    logger.error(msg); NdtLog(msg ); # works
    render json: {error: msg}, status: 500; #logger.error(e); raise e

  end
end

######################################################################
module AccountsHelper
  def account_action_button(account)
    if user_signed_in?
      if account.id == current_user.account_id
        link_to settings_profile_url, class: 'button logo-button' do
          safe_join(['', t('settings.edit_profile')])
          # safe_join(['logo_as_symbol', t('settings.edit_profile')])
        end
      elsif current_account.following?(account) || current_account.requested?(account)
        link_to account_unfollow_path(account), class: 'button logo-button button--destructive', data: {method: :post} do
          safe_join(['', t('accounts.unfollow')])
        end
      elsif !(account.memorial? || account.moved?)
        link_to account_follow_path(account), class: "button logo-button#{account.blocking?(current_account) ? ' disabled' : ''}", data: {method: :post} do
          safe_join(['', t('accounts.follow')])
        end
      end
    elsif !(account.memorial? || account.moved?)
      link_to account_remote_follow_path(account), class: 'button logo-button modal-button', target: '_new' do
        safe_join(['', t('accounts.follow')])
      end
    end
  end
end
#################################################################################

module BrandingHelper
  IMGLOGO_const = "<img draggable='false' alt='svg logo' title='logo' src='/emoji/267e.svg' height='44' />"
  IMGLOGOSMALL_const = "<img draggable='false' alt='svg logo' title='logo' src='/emoji/267e.svg' height='22' />"

  def sized_logo(height)
    return raw "<img draggable='false' alt='svg logo' title='logo' src='/emoji/267e.svg' height='#{height }' />"
     
  end

  def svg_logo_full # from a 'future' release
    logo_as_symbol(:wordmark)
  end

  def logo_as_symbol(version = :icon)

    # always just icon ; no 'word'
    case version
    when :icon
      sized_logo(79)
      #_logo_as_symbol_icon
    when :wordmark
      sized_logo(64) # noooo \\+ (raw "NDTogether")
      #_logo_as_symbol_wordmark
    when :wordmark2 # smaller
      sized_logo(21)
    end
  end

  def render_logo
    image_pack_tag('logo.svg', alt: 'Mastodon', class: 'logo logo--icon')
  end

  def render_symbol(version = :icon)
    path = begin
             case version
             when :icon
               'logo-symbol-icon.svg'
             when :wordmark
               'logo-symbol-wordmark.svg'
             end
           end

    render(file: Rails.root.join('app', 'javascript', 'images', path)).html_safe # rubocop:disable Rails/OutputSafety
  end
end
