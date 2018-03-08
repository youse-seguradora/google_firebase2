include: "firebase.model"

explore: sessions_base {
  extension: required
  from: sessions
  view_name: sessions
  join: user {
    sql: LEFT JOIN UNNEST([${sessions.user_dim}]) user ;;
    relationship: one_to_one
  }
  join: device {
    sql: LEFT JOIN UNNEST([${user.device_info}]) device ;;
    relationship: one_to_one
  }
  join: user_properties {
    sql: LEFT JOIN UNNEST(${user.user_properties}) user_properties ;;
    relationship: one_to_many
  }
  join: events {
    sql: LEFT JOIN UNNEST(ARRAY(
      (SELECT AS STRUCT e.*, ROW_NUMBER() OVER() as id FROM UNNEST(${sessions.event_dim}) e)
      )) events ;;
    relationship: one_to_many
  }
  join: event_parameters {
    sql:  LEFT JOIN UNNEST(${events.params}) as event_parameters ;;
    relationship: one_to_many
  }

}

view: sessions_base {
  extension: required
  sql_table_name:
    (SELECT *
      , ROW_NUMBER() OVER(
          PARTITION BY _TABLE_SUFFIX
          ORDER BY (SELECT MIN(timestamp_micros) FROM UNNEST(event_dim) )
          ) as id
    FROM `${app_events_table.SQL_TABLE_NAME}2*`) ;;


    dimension: id {
      primary_key:yes
      sql:CONCAT(
            CAST((SELECT MIN(timestamp_micros) FROM UNNEST(event_dim)) AS STRING)
            ,'_'
            , CAST(${TABLE}.id AS STRING) );;
    }

    dimension: event_dim {
      hidden: yes
      sql: ${TABLE}.event_dim ;;
    }

    dimension: user_dim {
      hidden: yes
      sql: ${TABLE}.user_dim ;;
    }

    filter: session_has_event {
      sql: (
        SELECT COUNT(*)
        FROM UNNEST(${TABLE}.event_dim) e
        WHERE {%condition%} e.name {%endcondition%}
        ) > 0;;
      suggest_explore: event_names_suggest
      suggest_dimension: event_name
    }

    measure: session_count {
      type: count
      drill_fields: [id,user_dim.user_id,events.event_count]
    }
  }

  view: device_base {
    extension: required
    dimension: device_category {
      type: string
      sql: ${TABLE}.device_category ;;
    }

    dimension: device_id {
      type: string
      sql: ${TABLE}.device_id ;;
    }

    dimension: device_model {
      type: string
      sql: ${TABLE}.device_model ;;
    }

    dimension: device_time_zone_offset_seconds {
      type: number
      sql: ${TABLE}.device_time_zone_offset_seconds ;;
    }

    dimension: limited_ad_tracking {
      type: yesno
      sql: ${TABLE}.limited_ad_tracking ;;
    }

    dimension: mobile_brand_name {
      type: string
      sql: ${TABLE}.mobile_brand_name ;;
    }

    dimension: mobile_marketing_name {
      type: string
      sql: ${TABLE}.mobile_marketing_name ;;
    }

    dimension: mobile_model_name {
      type: string
      sql: ${TABLE}.mobile_model_name ;;
    }

    dimension: platform_version {
      type: string
      sql: ${TABLE}.platform_version ;;
    }

    dimension: resettable_device_id {
      type: string
      sql: ${TABLE}.resettable_device_id ;;
    }

    dimension: user_default_language {
      type: string
      sql: ${TABLE}.user_default_language ;;
    }
  }

  view: user_base {
    extension: required
    dimension: app_info {
      hidden: yes
      sql: ${TABLE}.app_info ;;
    }

    dimension: bundle_info {
      hidden: yes
      sql: ${TABLE}.bundle_info ;;
    }

    dimension: device_info {
      hidden: yes
      sql: ${TABLE}.device_info ;;
    }

    dimension: first_open_timestamp_micros {
      type: number
      sql: ${TABLE}.first_open_timestamp_micros ;;
    }

    dimension: ltv_info {
      hidden: yes
      sql: ${TABLE}.ltv_info ;;
    }

    dimension: traffic_source {
      hidden: yes
      sql: ${TABLE}.traffic_source ;;
    }

    dimension: user_id {
      type: string
      sql: ${TABLE}.user_id ;;
    }

    dimension: user_properties {
      hidden: yes
      sql: ${TABLE}.user_properties ;;
    }

    # Geo

    dimension: city {
      group_label: "Geo"
      sql: ${TABLE}.geo_info.city ;;
    }

    dimension: continent {
      group_label: "Geo"
      sql: ${TABLE}.geo_info.continent ;;
    }

    dimension: country {
      group_label: "Geo"
      map_layer_name: countries
      sql: ${TABLE}.geo_info.country ;;
    }

    dimension: region {
      group_label: "Geo"
      sql: ${TABLE}.geo_info.region ;;
    }

    # Traffic Source

    dimension: user_acquired_campaign {
      group_label: "Traffic Source"
      sql: ${TABLE}.traffic_source.user_acquired_campaign ;;
    }

    dimension: user_acquired_medium {
      group_label: "Traffic Source"
      sql: ${TABLE}.traffic_source.user_acquired_medium ;;
    }

    dimension: user_acquired_source {
      group_label: "Traffic Source"
      sql: ${TABLE}.traffic_source.user_acquired_source ;;
    }

    # LTV Info, probably should be part of the session not user.
    dimension: currency {
      group_label: "LTV Info"
      type: string
      sql: ${TABLE}.ltv_info.currency ;;
    }

    dimension: revenue {
      group_label: "LTV Info"
      type: number
      sql: ${TABLE}.ltv_info.revenue ;;
    }

    # App Info
    dimension: app_id {
      group_label: "App"
      type: string
      sql: ${TABLE}.app_info.app_id ;;
    }

    dimension: app_instance_id {
      group_label: "App"
      type: string
      sql: ${TABLE}.app_info.app_instance_id ;;
    }

    dimension: app_platform {
      group_label: "App"
      type: string
      sql: ${TABLE}.app_info.app_platform ;;
    }

    dimension: app_store {
      group_label: "App"
      type: string
      sql: ${TABLE}.app_info.app_store ;;
    }

    dimension: app_version {
      group_label: "App"
      type: string
      sql: ${TABLE}.app_info.app_version ;;
    }

    # Bundle Info
    dimension: bundle_sequence_id {
      group_label: "Bundle Info"
      type: number
      sql: ${TABLE}.bundle_info.bundle_sequence_id ;;
    }

    dimension: server_timestamp_offset_micros {
      group_label: "Bundle Info"
      type: number
      sql: ${TABLE}.bundle_info.server_timestamp_offset_micros ;;
    }
  }

  view: user_properties {
    dimension: key {
      type: string
      sql: ${TABLE}.key ;;
    }

    dimension: value {
      hidden: yes
      sql: ${TABLE}.value.value ;;
    }
    dimension: index {
      type: number
      sql: ${TABLE}.value.index ;;
    }

    dimension: set_timestamp_usec {
      type: number
      sql: ${TABLE}.value.set_timestamp_usec ;;
    }

    dimension: value_as_number {
      group_label: "Value"
      type: number
      sql: COALESCE(${TABLE}.value.value.double_value,${TABLE}.value.value.int_value, ${TABLE}.value.value.float_value) ;;
    }
    dimension: string_value {
      group_label: "Value"
      sql: ${TABLE}.value.value.string_value ;;
    }
    dimension: double_value {
      group_label: "Value"
      sql: ${TABLE}.value.value.double_value ;;
    }
    dimension: int_value {
      group_label: "Value"
      sql: ${TABLE}.value.value.int_value ;;
    }
    dimension: float_value {
      group_label: "Value"
      sql: ${TABLE}.value.value.float_value ;;
    }
  }

  view: app_events_20170830__user_dim__traffic_source {
    dimension: user_acquired_campaign {
      type: string
      sql: ${TABLE}.user_acquired_campaign ;;
    }

    dimension: user_acquired_medium {
      type: string
      sql: ${TABLE}.user_acquired_medium ;;
    }

    dimension: user_acquired_source {
      type: string
      sql: ${TABLE}.user_acquired_source ;;
    }
  }

  view: events_base {
    extension: required
    dimension: id {
      primary_key: yes
      sql: CONCAT(${sessions.id},'_',CAST(${TABLE}.id AS STRING)) ;;
    }

    dimension:  firebase_event_origin {
      sql:  (SELECT value.string_value
            FROM UNNEST(${params})
            WHERE key = 'firebase_event_origin') ;;
    }

    dimension: date {
      type: string
      sql: ${TABLE}.date ;;
    }

    dimension: name {
      type: string
      sql: ${TABLE}.name ;;
      suggest_explore: event_names_suggest
      suggest_dimension: event_name

    }

    dimension: params {
      hidden: yes
      sql: ${TABLE}.params ;;
    }

    dimension: previous_timestamp_micros {
      type: number
      sql: ${TABLE}.previous_timestamp_micros ;;
    }

    dimension: timestamp_micros {
      type: number
      sql: ${TABLE}.timestamp_micros ;;
    }

    dimension: value_in_usd {
      type: number
      sql: ${TABLE}.value_in_usd ;;
    }

    dimension: parameters {
      sql: (SELECT
              STRING_AGG(
                CONCAT(key,'(',
                  COALESCE(value.string_value, CAST(value.double_value AS STRING),
                    CAST(value.int_value AS STRING), CAST(value.float_value AS STRING)),
                  ')'),
                ', '
              )
              FROM UNNEST(${TABLE}.params) );;
    }
    measure: event_count {
      type: count
      drill_fields: [timestamp_micros,id,name,parameters]
    }
  }

  # Each event has an array of parameters.
  view: event_parameters {
    dimension: key{
      type: string
      sql: ${TABLE}.key ;;
    }

    dimension: double_value {
      type: number
      sql: ${TABLE}.value.double_value ;;
    }

    dimension: float_value {
      type: number
      sql: ${TABLE}.value.float_value ;;
    }

    dimension: int_value {
      type: number
      sql: ${TABLE}.value.int_value ;;
    }

    dimension: string_value {
      type: string
      sql: ${TABLE}.value.string_value ;;
    }

    dimension: type {
      sql:
        CASE
          WHEN ${TABLE}.value.string_value IS NOT NULL THEN 'string_value'
          WHEN ${TABLE}.value.int_value IS NOT NULL THEN 'int_value'
          WHEN ${TABLE}.value.float_value IS NOT NULL THEN 'float_value'
          WHEN ${TABLE}.value.double_value IS NOT NULL THEN 'double_value'
        END;;
    }

    dimension: lookml_type {
      sql: CASE WHEN ${type} = 'string_value' THEN 'string' ELSE 'number' END ;;
    }

    dimension: lookml {
      sql:
        CONCAT(
           '  dimension: events_',${events.name},'.',${key}, '{\n'
          ,'    type: ',${lookml_type},'\n'
          ,'    sql:'
          ,'      CASE WHEN $','{name} = \'',${events.name},'\' THEN\n'
          ,'        (SELECT value.', ${type}, '\n'
          ,'        FROM UNNEST($','{params})\n'
          ,'        WHERE key = \'',${key},'\')\n'
          ,'      END ;\;\n'
          ,'  }\n'
        )
      ;;
    }
  }

  # Derived Tables

  # Make a list of all possible event types.
  explore: event_names_suggest {hidden:yes}
  view: event_names_suggest {
    derived_table: {
      persist_for: "24 hours"
      explore_source: sessions {
        column: event_name {field:events.name}
      }
    }
    dimension: event_name {}
  }
