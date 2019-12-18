# plantuml_generator
Generates simple plantUML Entity Relationship Diagram based on schema.rb file

#### Usage:
```
bundle install

bundle exec ruby plant_uml.rb /path/to/schema.rb # for full schema scan

# or

bundle exec ruby plant_uml.rb /path/to/schema.rb jira_boards jira_connections # for partial scan
```

#### Example of `schema.rb`:
```
ActiveRecord::Schema.define(version: 2019_08_28_114749) do

  create_table "jira_boards", force: :cascade do |t|
    t.integer "external_id", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.integer "connection_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["connection_id"], name: "index_jira_boards_on_connection_id"
  end

  create_table "jira_connections", force: :cascade do |t|
    t.string "username", null: false
    t.string "password", null: false
    t.string "site", null: false
    t.string "context_path", default: "", null: false
    t.string "auth_type", default: "basic", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "jira_sprints", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "state", null: false
    t.string "name", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.text "goal"
    t.integer "board_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["board_id"], name: "index_jira_sprints_on_board_id"
  end

  add_foreign_key "jira_boards", "jira_connections", column: "connection_id"
  add_foreign_key "jira_sprints", "jira_boards", column: "board_id"
end
```

#### Example of output
```
@startuml

hide circle
skinparam linetype ortho

entity "jira_boards" as jira_boards {
  id : integer <<generated>>
  --
  external_id : integer
  name : string
  type : string
  *connection_id : integer
  created_at : datetime
  updated_at : datetime
}


entity "jira_connections" as jira_connections {
  id : integer <<generated>>
  --
  username : string
  password : string
  site : string
  context_path : string
  auth_type : string
  created_at : datetime
  updated_at : datetime
}


entity "jira_sprints" as jira_sprints {
  id : integer <<generated>>
  --
  external_id : string
  state : string
  name : string
  start_date : datetime
  end_date : datetime
  goal : text
  *board_id : integer
  created_at : datetime
  updated_at : datetime
}


@enduml
```

![Example](/example.png)
