<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="template_demo_notes">      
    <querytext>
      select 
        n.template_demo_note_id, 
        n.title,
        to_char(o.creation_date, 'HH12:MI Month DD, YYYY') as creation_date,
        p.first_names || ' ' || p.last_name as creation_user_name,
        decode(acs_permission.permission_p(template_demo_note_id,
                                           :user_id,
                                           'write'),
               't', 1,
               'f', 0) as write_p,
        decode(acs_permission.permission_p(template_demo_note_id,
                                           :user_id,
                                           'admin'),
               't', 1,
               'f', 0) as admin_p,
        decode(acs_permission.permission_p(template_demo_note_id,
                                           :user_id,
                                           'delete'),
               't', 1,
               'f', 0) as delete_p
      from 
        template_demo_notes n, 
        acs_objects o,
        persons p
      where n.template_demo_note_id = o.object_id
        and n.template_demo_note_id = p.person_id
        and exists (select 1
                    from acs_object_party_privilege_map
                    where object_id = template_demo_note_id
                      and party_id = :user_id
                      and privilege = 'read')
      order by creation_date
    </querytext>
  </fullquery>
 
</queryset>
