ad_page_contract {
    Toggle translator mode on/off.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date October 24, 2002
    @cvs-id $Id$
} {
    {return_url "."}
}

lang::util::translator_mode_set [expr {![lang::util::translator_mode_p]}] 

ad_returnredirect $return_url

