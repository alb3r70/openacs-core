ad_page_contract {
    Display all information about a certain batch import operation.

    @author Peter marklund (peter@collaboraid.biz)
    @creation-date 2003-09-10
} {
    entry_id:integer
}

auth::sync::entry::get -entry_id $entry_id -array batch_action

set page_title "Batch Action \"$batch_action(entry_id)\""

set context [list [list "." "Authentication"] \
                  [list [export_vars -base authority { {authority_id $batch_action(authority_id)} }] \
                        "Authority\"$batch_action(authority_pretty_name)\""] \
                  [list [export_vars -base batch-job {{job_id $batch_action(job_id)}}] "One Job"] \
                 $page_title]

ad_form -name batch_action_form \
        -mode display \
        -display_buttons {} \
        -form {
            {entry_id:text(inform)
                {label "Entry ID"}                
            }
            {entry_time:text(inform)
                {label "Timestamp"}
            }
            {operation:text(inform)
                {label "Action type"}
            }
            {username:text(inform)
                {label "Username"}
            }
            {user_id:text(inform)
                {label "User"}
            }
            {success_p:text(inform)
                {label "Success"}
            }
            {message:text(inform)
                {label "Message"}
            }
            {element_messages:text(inform)
                {label "Element messages"}
            }            
        } -on_request {
            foreach element_name [array names batch_action] {
                # Prettify certain elements
                if { [regexp {_p$} $element_name] } {
                    set $element_name [ad_decode $batch_action($element_name) "t" "Yes" "No"]
                } elseif { [string equal $element_name "user_id"] && ![empty_string_p $batch_action($element_name)] } {
                    if { [catch {set $element_name [acs_community_member_link -user_id $batch_action($element_name)]}] } {
                        set $element_name $batch_action($element_name)
                    }
                } elseif { [string equal $element_name "element_messages"] && ![empty_string_p $batch_action($element_name)] } {
                    array set messages_array $batch_action($element_name)
                    append $element_name "<ul>"
                    foreach message_name [array names messages_array] {
                        append $element_name "<li>$message_name - $messages_array($message_name)</li>"
                    }
                    append $element_name "</ul>"
                } else {
                    set $element_name $batch_action($element_name)
                }
            }
        }
