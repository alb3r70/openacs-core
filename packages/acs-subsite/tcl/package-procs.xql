<?xml version="1.0"?>
<queryset>

<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	    select t.table_name as table, t.id_column as column
	      from acs_object_types t
	     where t.object_type = :object_type
	
      </querytext>
</fullquery>

 
<fullquery name="package_create.select_package_name">      
      <querytext>
      
	select t.package_name
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_generate_body.select_supertype_function_params">      
      <querytext>
      
	select args.argument_name
	  from user_arguments args
         where args.package_name =upper(:supertype_package_name)
	   and args.object_name='NEW'
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_create_attribute_list.select_type_info">      
      <querytext>
      
	select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
	  from acs_object_types t
	 where t.object_type = :object_type
    
      </querytext>
</fullquery>

 
<fullquery name="package_instantiate_object.package_select">      
      <querytext>
      
	    select t.package_name
	      from acs_object_types t
	     where t.object_type = :object_type
	
      </querytext>
</fullquery>

 
<fullquery name="package_object_view_helper.select_type_info">      
      <querytext>

	select t.table_name, t.id_column
          from acs_object_types t
	 where t.object_type = :object_type
	
      </querytext>
</fullquery>

 
</queryset>
