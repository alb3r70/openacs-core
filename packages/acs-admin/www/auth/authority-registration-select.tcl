ad_page_contract {
    Select a certain authority to be used to register
    users.

    @author Peter Marklund
} {
    authority_id:integer
}

# Check that the authority has a register implementation
auth::authority::get -authority_id $authority_id -array authority
if { [empty_string_p $authority(register_impl_id)] } {
    ad_return_error "No register driver" "The authority $authority(pretty_name) does not have a register driver and cannot register users"
}

parameter::set_value -package_id [apm_package_id_from_key acs-authentication] -parameter RegisterAuthority -value $authority(short_name)

ad_returnredirect [export_vars -base "." { authority_id }]