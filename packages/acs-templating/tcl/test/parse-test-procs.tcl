# 

ad_library {
    
    Tests for adp parsing
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-01-01
    @arch-tag: bc76f9ce-ed1c-49dd-a3be-617d5a78c838
    @cvs-id $Id$
}

aa_register_case template_variable {
    test adp variable parsing procedures
} {
    aa_run_with_teardown \
        -test_code {
            set code "=@test_array.test_key@"
            aa_true "Regular array var name detected" [regexp [template::adp_array_variable_regexp] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "test_array" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_key" $var]

            set code "=@formerror.test_array.test_key@"
            aa_true "Formerror regular array var name detected" [regexp [template::adp_array_variable_regexp] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "formerror" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_array.test_key" $var]            

            set code "=@test_array.test_key;noquote@"
            aa_true "Noquote array var name detected" [regexp [template::adp_array_variable_regexp_noquote] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "test_array" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_key" $var]

            set code "=@formerror.test_array.test_key;noquote@"
            aa_true "Noquote formerror array var name detected" [regexp [template::adp_array_variable_regexp_noquote] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "formerror" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_array.test_key" $var]
            
            
        }
}