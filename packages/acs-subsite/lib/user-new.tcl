# Expects parameters:
#
# self_register_p - Is the form for users who self register (1) or
#                   for administrators who create other users (0)?
# next_url        - Any url to redirect to after the form has been submitted. The
#                   variables user_id, password, and account_messages will be added to the URL. Optional.
# email           - Prepopulate the register form with given email. Optional.

# Set default parameter values
array set parameter_defaults {
    self_register_p 1
    next_url {}
}
foreach parameter [array names parameter_defaults] { 
    if { [template::util::is_nil $parameter] } { 
        set $parameter $parameter_defaults($parameter)
    }
}

# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

# Log user out if currently logged in, if specified in the includeable chunk's parameters, 
# e.g. not when creating accounts for other users
if { $self_register_p } {
    ad_user_logout 
}

# Pre-generate user_id for double-click protection
set user_id [db_nextval acs_object_id_seq]

ad_form -name register -export {next_url user_id} -form [auth::get_registration_form_elements] -on_request {
    # Populate elements from local variables
} -on_submit {

    array set creation_info [auth::create_user \
                                 -user_id $user_id \
                                 -verify_password_confirm \
                                 -username $username \
                                 -email $email \
                                 -first_names $first_names \
                                 -last_name $last_name \
                                 -screen_name $screen_name \
                                 -password $password \
                                 -password_confirm $password_confirm \
                                 -url $url \
                                 -secret_question $secret_question \
                                 -secret_answer $secret_answer]

    # Handle registration problems
    
    switch $creation_info(creation_status) {
        ok {
            # Continue below
        }
        default {
            # Adding the error to the first element, but only if there are no element messages
            if { [llength $creation_info(element_messages)] == 0 } {
                array set reg_elms [auth::get_registration_elements]
                set first_elm [lindex [concat $reg_elms(required) $reg_elms(optional)] 0]
                form set_error register $first_elm $creation_info(creation_message)
            }
                
            # Element messages
            foreach { elm_name elm_error } $creation_info(element_messages) {
                form set_error register $elm_name $elm_error
            }
            break
        }
    }

    switch $creation_info(account_status) {
        ok {
            # Continue below
        }
        default {
            # Display the message on a separate page
            ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { { message $creation_info(account_message) } }]
            ad_script_abort
        }
    }

} -after_submit {

    if { ![empty_string_p $next_url] } {
        # Add user_id and account_message to the URL
        
        ad_returnredirect [export_vars -base $next_url {user_id password {account_message $creation_info(account_message)}}]
        ad_script_abort
    }


    # User is registered and logged in
    if { ![exists_and_not_null return_url] } {
        # Redirect to subsite home page.
        set return_url [subsite::get_element -element url]
    }

    # Handle account_message
    if { ![empty_string_p $creation_info(account_message)] && $self_register_p } {
        # Only do this if user is self-registering
        # as opposed to creating an account for someone else

        ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-message" { { message $creation_info(account_message) } return_url }]
        ad_script_abort
    } else {
        # No messages
        ad_returnredirect $return_url
        ad_script_abort
    }
}
