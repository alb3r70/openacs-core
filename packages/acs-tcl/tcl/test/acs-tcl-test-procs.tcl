ad_library {
    Tcl helper procedures for the acs-automated-testing tests of
    the acs-tcl package.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 22 January 2003
}

ad_proc apm_test_callback_file_path {} {
    The path of the test file used to check that the callback proc executed ok.
} {
    return "[acs_package_root_dir acs-tcl]/tcl/test/callback_proc_test_file"
}

ad_proc apm_test_callback_proc {
    {-arg1:required}
    {-arg2:required}
} {
    # Write something to a file so that can check that the proc executed
    set file_path [apm_test_callback_file_path]
    set file_id [open $file_path w]
    puts $file_id "$arg1 $arg2"
    close $file_id
}


aa_register_case util__sets_equal_p {
    Test the util_sets_equal_p proc.

    @author Peter Marklund
} {
    aa_true "lists are identical sets" [util_sets_equal_p [list a a a b b c] [list c a a b b a]]
    aa_true "lists are identical sets 2" [util_sets_equal_p [list a b c] [list a b c]]
    aa_false "lists are not identical sets" [util_sets_equal_p [list a a a b b c] [list c c a b b a]]
    aa_false "lists are not identical sets 2" [util_sets_equal_p [list a b c] [list a b c d]]
}

# By stubbing this proc we can define callbacks valid only during testing 
# that are guaranteed not to interfere with any real callbacks in the system
aa_stub apm_supported_callback_types {
    return [list __test-callback-type]
}

aa_stub apm_arg_names_for_callback_type {
    return [list arg1 arg2]
}

aa_register_case apm__test_info_file {
    Test that the procs for interfacing with package info files - 
    apm_generate_package_spec and 
    apm_read_package_info_file - handle the newly added
    callback and auto-mount tags properly.

    @creation-date 22 January 2003
    @author Peter Marklund
} {
    set test_dir "[acs_package_root_dir acs-tcl]/tcl/test"
    set spec_path "${test_dir}/tmp-test-info-file.xml"
    set allowed_type [lindex [apm_supported_callback_types] 0]
    array set callback_array [list unknown-type proc_name1 $allowed_type proc_name2]
    set version_id [db_string aa_version_id {select version_id 
                                            from apm_enabled_package_versions 
                                            where package_key = 'acs-automated-testing'}]
    set auto_mount_orig [db_string aa_auto_mount {select auto_mount
                                             from apm_package_versions
                                             where version_id = :version_id}]
    set auto_mount $auto_mount_orig
    if { [empty_string_p $auto_mount] } {
        set auto_mount "test_auto_mount_dir"
        db_dml set_test_mount {update apm_package_versions
                               set auto_mount = :auto_mount
                               where version_id = :version_id}
        } 

    set error_p [catch {         
        # Add a few test callbacks
        foreach {type proc} [array get callback_array] {
          db_dml insert_callback {insert into apm_package_callbacks
                                       (version_id, type, proc)
                                values (:version_id, :type, :proc)}
        }
    
        # Get the xml string
        set spec [apm_generate_package_spec $version_id]
    
        # Write xml to file
        set spec_file_id [open $spec_path w]
        puts $spec_file_id $spec
        close $spec_file_id
    
        # Read the xml file
        array set spec_array [apm_read_package_info_file $spec_path]
    
        # Assert that info parsed from xml file is correct
        array set parsed_callback_array $spec_array(callbacks)
    
        aa_true "Only one permissible callback should be returned, got array [array get parsed_callback_array]" \
                [expr [llength [array names parsed_callback_array]] == 1]
    
        aa_equals "Checking name of callback of allowed type $allowed_type" \
                $parsed_callback_array($allowed_type) $callback_array($allowed_type)

        aa_equals "Checking that auto-callback is correct" $spec_array(auto-mount) $auto_mount
            
    } error]

    # Teardown
    file delete $spec_path
    foreach {type proc} [array get callback_array] {
      db_dml remove_callback {delete from apm_package_callbacks 
                              where version_id = :version_id
                              and type = :type }
    }
    db_dml reset_auto_mount {update apm_package_versions
                             set auto_mount = :auto_mount_orig
                             where version_id = :version_id}


    if { $error_p } {
        global errorInfo
        error "$error - $errorInfo"
    }
}

aa_register_case apm__test_callback_get_set {
    Test the procs apm_get_callback_proc,
                   apm_set_callback_proc,
                   apm_package_install_callbacks
                   apm_remove_callback_proc,
                   apm_post_instantiation_tcl_proc_from_key.

    @author Peter Marklund
} {
    # The proc should not accept an invalid callback type
    set invalid_type "not-allowed-type"
    set error_p [catch {apm_get_callback_proc -type $invalid_type -package_key acs-kernel} error]
    aa_true "invalid types should result in error, got error: $error" $error_p
    
    # Try setting a package callback proc
    set callback_type [lindex [apm_supported_callback_types] 0]
    set proc_name "test_proc"
    set package_key "acs-automated-testing"
    set version_id [apm_version_id_from_package_key $package_key]

    set error_p [catch {
        apm_package_install_callbacks [list $callback_type $proc_name] $version_id
    
        # Retrieve the callback proc
        set retrieved_proc_name \
                [apm_get_callback_proc -package_key $package_key \
                                       -type $callback_type]
        aa_equals "apm_get_callback_proc retrieve callback proc" \
                  $retrieved_proc_name $proc_name
    } error]

    # Teardown
    apm_remove_callback_proc -package_key $package_key -type $callback_type

    if { $error_p } {
        global errorInfo
        error "$error - $errorInfo"
    }
}

aa_register_case apm__test_callback_invoke {
    Test the proc apm_invoke_callback_proc

    @author Peter Marklund
} {
    set package_key acs-automated-testing
    set version_id [apm_version_id_from_package_key $package_key]
    set type [lindex [apm_supported_callback_types] 0]
    set file_path [apm_test_callback_file_path]

    set error_p [catch {

        # Set the callback to be to our little test proc
        apm_set_callback_proc -version_id $version_id -type $type "apm_test_callback_proc"
    
        apm_invoke_callback_proc -version_id $version_id -arg_list [list arg1 value1 arg2 value2] -type $type
    
        set file_id [open $file_path r]
        set file_contents [read $file_id]
        aa_equals "The callback proc should have been executed and written argument values to file" \
                [string trim $file_contents] "value1 value2"
        close $file_id
    
        # Provide invalid argument list and the invoke proc should bomb
        # TODO...
    } error]

    # Teardown
    file delete $file_path
    apm_remove_callback_proc -package_key $package_key -type $type

    if { $error_p } {
        global errorInfo
        error "$error - $errorInfo"
    }
}

aa_register_case xml_get_child_node_content_by_path {
    Test xml_get_child_node_content_by_path
} {
    set tree [xml_parse -persist {
<enterprise>
  <properties>
    <datasource>Dunelm Services Limited</datasource>
    <target>Telecommunications LMS</target>
    <type>DATABASE UPDATE</type>
    <datetime>2001-08-08</datetime>
  </properties>
  <person recstatus = "1">
    <comments>Add a new Person record.</comments>
    <sourcedid>
      <source>Dunelm Services Limited</source>
      <id>CK1</id>
    </sourcedid>
    <name>
      <fn>Clark Kent</fn>
      <sort>Kent, C</sort>
      <nickname>Superman</nickname>
    </name>
    <demographics>
      <gender>2</gender>
    </demographics>
    <adr>
      <extadd>The Daily Planet</extadd>
      <locality>Metropolis</locality>
      <country>USA</country>
    </adr>
  </person>
</enterprise>
    }]

    set root_node [xml_doc_get_first_node $tree]

    aa_equals "person -> name -> nickname is Superman" \
        [xml_get_child_node_content_by_path $root_node { { person name nickname } }] "Superman"

    aa_equals "Same, but after trying a couple of non-existent paths or empty notes" \
        [xml_get_child_node_content_by_path $root_node { { does not exist } { properties } { person name nickname } { person sourcedid id } }] "Superman"
    aa_equals "properties -> datetime" \
        [xml_get_child_node_content_by_path $root_node { { person commments foo } { person name first_names } { properties datetime } }] "2001-08-08"


}

aa_register_case -cats {
    script
} -on_error {
    site_node::get_children returns root node!
} site_node_get_children {
    Test site_node::get_children
} {
    # Start with a known site-map entry
    set node_id [site_node::get_node_id -url "/"]

    set child_node_ids [site_node::get_children \
			    -all \
			    -element node_id \
			    -node_id $node_id]

    # lsearch returns '-1' if not found
    aa_equals "site_node::get_children does not return root node" [lsearch -exact $child_node_ids $node_id] -1


    # -package_key
    set nodes [site_node::get_children -all -element node_id -node_id $node_id -filters { package_key "acs-admin" }]

    aa_equals "package_key arg. identical to -filters" \
        [site_node::get_children -all -element node_id -node_id $node_id -package_key "acs-admin"] \
        $nodes
    
    aa_equals "Found exactly one acs-admin node" [llength $nodes] 1


    # -package_type
    set nodes [site_node::get_children -all -element node_id -node_id $node_id -filters { package_type "apm_service" }]
    aa_equals "package_type arg. identical to filter_element package_type" \
        [site_node::get_children -all -element node_id -node_id $node_id -package_type "apm_service"] \
        $nodes
    
    aa_true "Found at least one apm_service node" [expr [llength $nodes] > 0]

    # nonexistent package_type
    aa_true "No nodes with package type 'foo'" \
        [expr [llength [site_node::get_children -all -element node_id -node_id $node_id -package_type "foo"]] == 0]

    
}

aa_register_case text_to_html {
    Test code the supposedly causes ad_html_to_text to break
} {
    
    # Test bad <<<'s

    set offending_post {><<<}
    set errno [catch { set text_version [ad_html_to_text -- $offending_post] } errmsg]

    if { ![aa_equals "Does not bomb" $errno 0] } {
        global errorInfo
        aa_log "errmsg: $errmsg"
        aa_log "errorInfo: $errorInfo"
    } else {
        aa_equals "Expected identical result" $text_version $offending_post
    }

    # Test offending post sent by Dave Bauer

    set offending_post {
I have a dynamically assigned ip address, so I use dyndns.org to
change
addresses for my acs server.
Mail is sent to any yahoo address fine. Mail sent to aol fails. I am
not running a dns server on my acs box. What do I need to do to
correct this problem?<br>
Here's my error message:<blockquote>
            Mail Delivery Subsystem<br>
<MAILER-DAEMON@testdsl.homeip.net>  | Block
            Address | Add to Address Book<br>
       To:
            gmt3rd@yahoo.com<br>
 Subject:
            Returned mail: Service unavailable
<p>


The original message was received at Sat, 17 Mar 2001 11:48:57 -0500
from IDENT:nsadmin@localhost [127.0.0.1]
<br>
   ----- The following addresses had permanent fatal errors -----
gmt3rd@aol.com
<br>
   ----- Transcript of session follows -----<p>
... while talking to mailin-04.mx.aol.com.:
<<< 550-AOL no longer accepts connections from dynamically assigned 
<<< 550-IP addresses to our relay servers.  Please contact your ISP
<<< 550 to have your mail redirected through your ISP's SMTP servers.
... while talking to mailin-02.mx.aol.com.:
>>> QUIT
<p>

                              Attachment: Message/delivery-status

Reporting-MTA: dns; testdsl.homeip.net
Received-From-MTA: DNS; localhost
Arrival-Date: Sat, 17 Mar 2001 11:48:57 -0500

Final-Recipient: RFC822; gmt3rd@aol.com
Action: failed
Status: 5.5.0
Remote-MTA: DNS; mailin-01.mx.aol.com
Diagnostic-Code: SMTP; 550-AOL no longer accepts connections from 
dynamically assigned 
Last-Attempt-Date: Sat, 17 Mar 2001 11:48:57 -0500

</blockquote>
<p>
anybody have any ideas?
    }

    set errno [catch { set text_version [ad_html_to_text -- $offending_post] } errmsg]

    if { ![aa_equals "Does not bomb" $errno 0] } {
        global errorInfo
        aa_log "errmsg: $errmsg"
        aa_log "errorInfo: $errorInfo"
    } else {
        aa_log "Text version: $text_version"
    }

    # Test placement of [1] reference
    set html {Here is <a href="http://openacs.org">http://openacs.org</a> my friend}

    set text_version [ad_html_to_text -- $html]

    aa_log "Text version: $text_version"
}

aa_register_case ad_page_contract_filters {
    Test ad_page_contract_filters 
} {
    set filter integer
    foreach { value result } { "1" 1 "a" 0 "1.2" 0 "'" 0 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }

    set filter naturalnum
    foreach { value result } { "1" 1 "-1" 0 "a" 0 "1.2" 0 "'" 0 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }

    set filter html
    foreach { value result } { "'" 1 "<p>" 1 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }

    set filter nohtml
    foreach { value result } { "a" 1 "<p>" 0 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }
}

aa_register_case export_vars {
    Testing export_vars
} {
    set foo 1
    set bar {}

    aa_equals "{ foo bar }" \
        [export_vars { foo bar }] \
        "foo=1&bar="
    
    aa_equals "-no_empty { foo bar }" \
        [export_vars -no_empty { foo bar }] \
        "foo=1"
    
    aa_equals "-no_empty { foo bar { baz greble } }" \
        [export_vars -no_empty { foo bar { baz greble } }] \
        "foo=1&baz=greble"
    
    aa_equals "-no_empty -override { { bar \"\" } } { foo bar }" \
        [export_vars -no_empty -override { { bar "" } } { foo bar }] \
        "foo=1&bar=" \
        
    aa_equals "-no_empty -override { { baz greble } } { foo bar }" \
        [export_vars -no_empty -override { baz } { foo bar }] \
        "foo=1"
    
    aa_equals "-no_empty { foo { bar \"\" } }" \
        [export_vars -no_empty { foo { bar "" } }] \
        "foo=1&bar="

    # Test base with query vars
    set var1 a
    set var2 {}
    set base [export_vars -base test-page { foo bar }]
    set export_no_base [export_vars {var1 var2}]
    aa_equals "base with query vars" \
        [export_vars -base $base {var1 var2}] \
        "$base&$export_no_base"        

    # Test base without query vars
    set base test-page
    aa_equals "base without query vars" \
        [export_vars -base $base {var1 var2}] \
        "$base?$export_no_base"            
}

aa_register_case site_node_verify_folder_name {
    Testing site_node::veriy_folder_name
} {
    set main_site_node_id [site_node::get_node_id -url /]
    
    # Try a few folder names which we know exist
    aa_equals "Folder name 'user' is not allowed" \
        [site_node::verify_folder_name -parent_node_id $main_site_node_id -folder "user"] ""
    aa_equals "Folder name 'pvt' is not allowed" \
        [site_node::verify_folder_name -parent_node_id $main_site_node_id -folder "pvt"] ""

    # Try one we believe will be allowed
    set folder [ad_generate_random_string]
    aa_equals "Folder name '$folder' is allowed" \
        [site_node::verify_folder_name -parent_node_id $main_site_node_id -folder $folder] $folder
    
    # Try the code that generates a folder name
    # (We only want to try this if there doesn't happen to be a site-node named user-2)
    if { ![site_node::exists_p -url "/register-2"] } {
        aa_equals "Instance name 'Register'" \
            [site_node::verify_folder_name -parent_node_id $main_site_node_id -instance_name "register"] "register-2"
    }

    set first_child_node_id [lindex [site_node::get_children -node_id $main_site_node_id -element node_id] 0]
    set first_child_name [site_node::get_element -node_id $first_child_node_id -element name]

    aa_equals "Renaming folder '$first_child_name' ok" \
            [site_node::verify_folder_name \
                 -parent_node_id $main_site_node_id \
                 -folder $first_child_name \
                 -current_node_id $first_child_node_id] $first_child_name
        
    aa_false "Creating new folder named '$first_child_name' not ok" \
        [string equal [site_node::verify_folder_name \
                           -parent_node_id $main_site_node_id \
                           -folder $first_child_name] $first_child_name]
        
}


aa_register_case -cats db db__transaction { 
    test db_transaction
} {

    # create a temp table for testing 
    catch {db_dml remove_table {drop table tmp_db_transaction_test}}
    db_dml new_table {create table tmp_db_transaction_test (a integer constraint tmp_db_transaction_test_pk primary key, b integer)}


    aa_equals "Test we can insert a row in a db_transaction clause" \
        [db_transaction {db_dml test1 {insert into tmp_db_transaction_test(a,b) values (1,2)}}] ""
    
    aa_equals "Verify clean insert worked" \
        [db_string check1 {select a from tmp_db_transaction_test} -default missing] 1
    
    # verify the on_error clause is called
    set error_called 0
    catch {db_transaction { set foo } on_error {set error_called 1}} errMsg
    aa_equals "error clause invoked on tcl error" \
        $error_called 1

    # Check that the tcl error propigates up from the code block
    set error_p [catch {db_transaction { error "BAD CODE"}} errMsg]
    aa_equals "Tcl error propigates to errMsg from code block" \
        $errMsg "Transaction aborted: BAD CODE"

    # Check that the tcl error propigates up from the on_error block
    set error_p [catch {db_transaction {set foo} on_error { error "BAD CODE"}} errMsg]
    aa_equals "Tcl error propigates to errMsg from on_error block" \
        $errMsg "BAD CODE"


    # check a dup insert fails and the primary key constraint comes back in the error message.
    set error_p [catch {db_transaction {db_dml test2 {insert into tmp_db_transaction_test(a,b) values (1,2)}}} errMsg]
    aa_true "error thrown inserting duplicate row" $error_p
    aa_true "error message contains constraint violated" [string match -nocase {*tmp_db_transaction_test_pk*} $errMsg]
    
    # check a sql error calls on_error clause
    set error_called 0
    set error_p [catch {db_transaction {db_dml test3 {insert into tmp_db_transaction_test(a,b) values (1,2)}} on_error {set error_called 1}} errMsg]
    aa_false "no error thrown with on_error clause" $error_p
    aa_equals "error message empty with on_error clause" \
        $errMsg {}
                 
    # Check on explicit aborts
    set error_p [catch {
        db_transaction {
            db_dml test4 {
                insert into tmp_db_transaction_test(a,b) values (2,3)
            }
            db_abort_transaction 
        }
    } errMsg]
    aa_true "error thrown with explicit abort" $error_p
    aa_equals "row not inserted with explicit abort" \
        [db_string check4 {select a from tmp_db_transaction_test where a = 2} -default missing] "missing"
    
    # Check a failed sql command can do sql in the on_error block
    set sqlok {}
    set error_p [catch {
        db_transaction {
            db_dml test5 {
                insert into tmp_db_transaction_test(a,b) values (1,2)
            }
        } on_error { 
            set sqlok [db_string check5 {select a from tmp_db_transaction_test where a = 1}]
        }
    } errMsg]
    aa_false "No error thrown doing sql in on_error block" $error_p
    aa_equals "Query succeeds in on_error block" \
        $sqlok 1


    # Check a failed transactions dml is rolled back in the on_error block
    set error_p [catch {
        db_transaction {
            error "BAD CODE"
        } on_error { 
            db_dml test6 {
                insert into tmp_db_transaction_test(a,b) values (3,4)
            }
        }
    } errMsg]
    aa_false "No error thrown doing insert dml in on_error block" $error_p
    aa_equals "Insert in on_error block rolled back, code error" \
        [db_string check6 {select a from tmp_db_transaction_test where a = 3} -default {missing}] missing


    # Check a failed transactions dml is rolled back in the on_error block
    set error_p [catch {
        db_transaction {
            db_dml test7 {
                insert into tmp_db_transaction_test(a,b) values (1,2)
            }
        } on_error { 
            db_dml test8 {
                insert into tmp_db_transaction_test(a,b) values (3,4)
            }
        }
    } errMsg]
    aa_false "No error thrown doing insert dml in on_error block" $error_p
    aa_equals "Insert in on_error block rolled back, sql error" \
        [db_string check8 {select a from tmp_db_transaction_test where a = 3} -default {missing}] missing

    

    # check nested db_transactions work properly with clean code
    set error_p [catch { 
        db_transaction { 
            db_dml test9 {
                insert into tmp_db_transaction_test(a,b) values (5,6)
            }
            db_transaction { 
                db_dml test10 {
                    insert into tmp_db_transaction_test(a,b) values (6,7)
                }
            }
        }
    } errMsg]
    aa_false "No error thrown doing nested db_transactions" $error_p    
    aa_equals "Data inserted in  outer db_transaction" \
        [db_string check9 {select a from tmp_db_transaction_test where a = 5} -default {missing}] 5
    aa_equals "Data inserted in nested db_transaction" \
        [db_string check10 {select a from tmp_db_transaction_test where a = 6} -default {missing}] 6



    # check error in outer transaction rolls back nested transaction
    set error_p [catch { 
        db_transaction { 
            db_dml test11 {
                insert into tmp_db_transaction_test(a,b) values (7,8)
            }
            db_transaction { 
                db_dml test12 {
                    insert into tmp_db_transaction_test(a,b) values (8,9)
                }
            }
            error "BAD CODE"
        }
    } errMsg]
    aa_true "Error thrown doing nested db_transactions" $error_p    
    aa_equals "Data rolled back in outer db_transactions with error in outer" \
        [db_string check11 {select a from tmp_db_transaction_test where a = 7} -default {missing}] missing
    aa_equals "Data rolled back in nested db_transactions with error in outer" \
        [db_string check12 {select a from tmp_db_transaction_test where a = 8} -default {missing}] missing

    # check error in outer transaction rolls back nested transaction
    set error_p [catch { 
        db_transaction { 
            db_dml test13 {
                insert into tmp_db_transaction_test(a,b) values (9,10)
            }
            db_transaction { 
                db_dml test14 {
                    insert into tmp_db_transaction_test(a,b) values (10,11)
                }
                error "BAD CODE"
            }
        }
    } errMsg]
    aa_true "Error thrown doing nested db_transactions: $errMsg" $error_p    
    aa_equals "Data rolled back in outer db_transactions with error in nested" \
        [db_string check13 {select a from tmp_db_transaction_test where a = 9} -default {missing}] missing
    aa_equals "Data rolled back in nested db_transactions with error in nested" \
        [db_string check14 {select a from tmp_db_transaction_test where a = 10} -default {missing}] missing

    db_dml drop_table {drop table tmp_db_transaction_test}
}


aa_register_case util__subset_p {
    Test the util_subset_p proc.

    @author Peter Marklund
} {
    aa_true "List is a subset" [util_subset_p [list c b] [list c a a b b a]]
    aa_true "List is a subset" [util_subset_p [list a b c] [list c a b]]
    aa_false "List is not a subset" [util_subset_p [list a a a b b c] [list c c a b b a]]
    aa_false "List is not a subset" [util_subset_p [list a b c d] [list a b c]]

    aa_equals "List is a subset" [util_get_subset_missing [list a a a b b c] [list c c a b b a]] [list]
    aa_equals "List is a subset" [util_get_subset_missing [list a a a b b c] [list c c a b b a]] [list]
    aa_equals "List is not a subset" [util_get_subset_missing [list a b c d] [list a b c]] [list d]
}

