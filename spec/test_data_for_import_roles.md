input:

```csv
meta_key_id,label_de,label_en
zhdk_bereich:roles,aaa-de,aaa-en
zhdk_bereich:roles,b,
zhdk_bereich:roles,"yö yö","yo yo"
```

db:

```ruby
# query
Role.all.order('created_at DESC').first(3).map {|r| r.slice('meta_key_id', 'labels', 'creator_id')}

# should match
[{"meta_key_id"=>"zhdk_bereich:roles", "labels"=>{"de"=>"aaa-de", "en"=>"aaa-en"}, "creator_id"=>test_user.id},
 {"meta_key_id"=>"zhdk_bereich:roles", "labels"=>{"de"=>"b", "en"=>nil}, "creator_id"=>test_user.id},
 {"meta_key_id"=>"zhdk_bereich:roles", "labels"=>{"de"=>"yö yö", "en"=>"yo yo"}, "creator_id"=>test_user.id}]
```
