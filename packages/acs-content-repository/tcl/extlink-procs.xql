<?xml version="1.0"?>
<queryset>

   <fullquery name="content_extlink::edit.extlink_update_extlink">      
      <querytext>

        update cr_extlinks
        set url = :url,
          label = :label,
          description = :description
        where extlink_id = :extlink_id

      </querytext>
   </fullquery>

</queryset>
