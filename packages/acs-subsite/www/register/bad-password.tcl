# /www/register/bad-password.tcl

ad_page_contract {
    Informs the user that they have typed in a bad password.
    @cvs-id $Id$
} {
    {user_id:naturalnum}
    {return_url ""}
} -properties {
    system_name:onevalue
    email_forgotten_password_p:onevalue
    user_id:onevalue
    subsite_url:onevalue
}

set subsite_url [subsite::get_element -element url]

set email_forgotten_password_p [ad_parameter EmailForgottenPasswordP security 1]

set system_name [ad_system_name]

set email_password_url "email-password?user_id=$user_id"

ad_return_template

