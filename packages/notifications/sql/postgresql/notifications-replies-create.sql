
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--

--
-- The queue of messages coming back
--

create table notification_replies (
       reply_id                   integer not null
                                  constraint notif_repl_repl_id_fk references acs_objects(object_id)
                                  constraint notif_repl_repl_id_pk primary key,
       object_id                  integer not null
                                  constraint notif_repl_obj_id_fk references acs_objects(object_id),
       type_id                    integer not null
                                  constraint notif_repl_type_id_fk references notification_types(type_id),
       from_user                  integer not null
                                  constraint notif_repl_from_fk references users(user_id),
       subject                    varchar(100),
       content                    text,
       reply_date                 timestamp
);


select acs_object_type__create_type (
            'notification_reply',
            'Notification Reply',
            'Notification Replies',
            'acs_object',
            'notification_replies',
            'reply_id',
            'notification_reply',
            'f',
            NULL,
            NULL
);
