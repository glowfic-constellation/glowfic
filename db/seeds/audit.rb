Audited::Audit.create!([
  {
    auditable_id: 1,
    auditable_type: "Post",
    user_id: 5,
    user_type: "User",
    action: "create",
    audited_changes: {
      "board_id"=>5,
      "user_id"=>5,
      "subject"=>"sample thread",
      "privacy"=>0,
      "status"=>0,
      "section_id"=>nil,
      "description"=>"",
      "authors_locked"=>false,
      "character_id"=>nil,
      "character_alias_id"=>nil,
      "icon_id"=>4,
      "content"=>""
    },
    version: 1,
    remote_address: "127.0.0.1",
    created_at: "2018-11-27 02:25:53",
    request_uuid: "7c24e660-fc3e-4aee-a401-04ea95e4797c"
  },
  {
    auditable_id: 1,
    auditable_type: "Reply",
    associated_id: 1,
    associated_type: "Post",
    user_id: 5,
    user_type: "User",
    action: "create",
    audited_changes: {
      "post_id"=>1,
      "user_id"=>5,
      "content"=>"<p>reply</p>",
      "character_id"=>nil,
      "icon_id"=>4,
      "thread_id"=>nil,
      "character_alias_id"=>nil
    },
    version: 1,
    remote_address: "127.0.0.1",
    created_at: "2018-11-27 04:53:37",
    request_uuid: "2b3f836c-a6a6-4cd6-960d-0bca7794a9e1"
  },
  {
    auditable_id: 2,
    auditable_type: "Reply",
    associated_id: 1,
    associated_type: "Post",
    user_id: 5,
    user_type: "User",
    action: "create",
    audited_changes: {
      "post_id"=>1,
      "user_id"=>5,
      "content"=>"<p>reply</p>",
      "character_id"=>nil,
      "icon_id"=>4,
      "thread_id"=>nil,
      "character_alias_id"=>nil
    },
    version: 1,
    remote_address: "127.0.0.1",
    created_at: "2018-11-27 04:53:50",
    request_uuid: "f0061941-b7df-4435-96c8-932a127926fe"
  },
  {
    auditable_id: 3,
    auditable_type: "Reply",
    associated_id: 1,
    associated_type: "Post",
    user_id: 1,
    user_type: "User",
    action: "create",
    audited_changes: {
      "post_id"=>1,
      "user_id"=>1,
      "content"=>"reply",
      "character_id"=>nil,
      "icon_id"=>1,
      "thread_id"=>nil,
      "character_alias_id"=>nil
    },
    version: 1,
    remote_address: "127.0.0.1",
    created_at: "2018-12-06 00:04:35",
    request_uuid: "e72b914c-a206-48b9-968d-2b9d9418d2cd"
  },
  {
    auditable_id: 3,
    auditable_type: "Reply",
    associated_id: 1,
    associated_type: "Post",
    user_id: 1,
    user_type: "User",
    action: "update",
    audited_changes: {
      "character_id"=>[nil, 6],
      "icon_id"=>[1, 11]
    },
    version: 2,
    remote_address: "127.0.0.1",
    created_at: "2018-12-06 00:05:05",
    request_uuid: "a9e1edc6-549f-4fa5-8e62-e669e81315dc"
  },
  {
    auditable_id: 3,
    auditable_type: "Reply",
    associated_id: 1,
    associated_type: "Post",
    user_id: 1,
    user_type: "User",
    action: "update",
    audited_changes: {
      "content"=>["reply", "edited reply"]
    },
    version: 3,
    remote_address: "127.0.0.1",
    created_at: "2018-12-06 00:05:13",
    request_uuid: "fe533fd1-87fe-4269-94c9-aa20fd486a8b"
  },
])
