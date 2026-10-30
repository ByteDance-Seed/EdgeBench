use crate::search::temporal::*;
use cas_types::{Entity, EntityType, RelationType};
use chrono::NaiveDate;




#[test]
fn test_temporal_query_parse_last_week() {
    let query = TemporalQuery::parse("last week").unwrap();
    let week_ago = Utc::now() - Duration::days(5);
    assert!(query.period.contains(&week_ago));
}


#[test]
fn test_temporal_query_parse_month() {
    let query = TemporalQuery::parse("January 2025").unwrap();
    let jan15 = NaiveDate::from_ymd_opt(2025, 1, 15)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&jan15));
}

#[test]
fn test_temporal_query_parse_in_month() {
    let query = TemporalQuery::parse("in Feb 2025").unwrap();
    let feb10 = NaiveDate::from_ymd_opt(2025, 2, 10)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&feb10));
}


#[test]
fn test_relationship_overlap() {
    let period = TimePeriod::month(2025, 1).unwrap();

    // Relationship valid during January
    let mut rel1 = Relationship::new(
        "rel1".to_string(),
        "e1".to_string(),
        "e2".to_string(),
        RelationType::WorksOn,
    );
    rel1.valid_from = Some(
        NaiveDate::from_ymd_opt(2024, 12, 1)
            .unwrap()
            .and_hms_opt(0, 0, 0)
            .unwrap()
            .and_utc(),
    );
    rel1.valid_until = Some(
        NaiveDate::from_ymd_opt(2025, 2, 1)
            .unwrap()
            .and_hms_opt(0, 0, 0)
            .unwrap()
            .and_utc(),
    );
    assert!(period.overlaps_relationship(&rel1));

    // Relationship ended before January
    let mut rel2 = rel1.clone();
    rel2.valid_until = Some(
        NaiveDate::from_ymd_opt(2024, 12, 31)
            .unwrap()
            .and_hms_opt(23, 59, 59)
            .unwrap()
            .and_utc(),
    );
    assert!(!period.overlaps_relationship(&rel2));
}

#[test]
fn test_entity_history() {
    let entity = Entity::new("e1".to_string(), "Alice".to_string(), EntityType::Person);

    let mut rel1 = Relationship::new(
        "rel1".to_string(),
        "e1".to_string(),
        "proj1".to_string(),
        RelationType::WorksOn,
    );
    rel1.valid_from = Some(Utc::now() - Duration::days(30));
    rel1.valid_until = Some(Utc::now() - Duration::days(10));

    let rel2 = Relationship::new(
        "rel2".to_string(),
        "e1".to_string(),
        "proj2".to_string(),
        RelationType::WorksOn,
    );

    let history = EntityHistory::from_relationships(entity, vec![rel1, rel2]);

    // Should have events for both relationships
    assert!(!history.relationship_history.is_empty());
}


#[test]
fn test_temporal_query_parse_this_week() {
    let before = Utc::now();
    let query = TemporalQuery::parse("this week").unwrap();
    // Period should contain time before parsing (now at parse time >= before)
    assert!(query.period.contains(&before));
    assert_eq!(query.description, "this week");
}

#[test]
fn test_temporal_query_parse_this_month() {
    let before = Utc::now();
    let query = TemporalQuery::parse("this month").unwrap();
    assert!(query.period.contains(&before));
    assert_eq!(query.description, "this month");
}


#[test]
fn test_temporal_query_parse_days_ago() {
    let query = TemporalQuery::parse("30 days ago").unwrap();
    let target = Utc::now() - Duration::days(30);
    // The window is +/- 12 hours around the target
    assert!(query.period.contains(&target));
    assert_eq!(query.description, "30 days ago");
}

#[test]
fn test_temporal_query_parse_weeks_ago() {
    let query = TemporalQuery::parse("2 weeks ago").unwrap();
    let target = Utc::now() - Duration::days(14);
    assert!(query.period.contains(&target));
    assert_eq!(query.description, "2 weeks ago");
}

#[test]
fn test_temporal_query_parse_month_ago() {
    let query = TemporalQuery::parse("1 month ago").unwrap();
    let target = Utc::now() - Duration::days(30);
    assert!(query.period.contains(&target));
    assert_eq!(query.description, "1 month ago");
}

// Flexible date format tests

#[test]
fn test_parse_date_flexible_iso() {
    let date = parse_date_flexible("2025-01-15").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());
}

#[test]
fn test_parse_date_flexible_us_format() {
    let date = parse_date_flexible("01/15/2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());

    // Without leading zeros
    let date = parse_date_flexible("1/5/2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 5).unwrap());
}

#[test]
fn test_parse_date_flexible_eu_format_dots() {
    let date = parse_date_flexible("15.01.2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());
}

#[test]
fn test_parse_date_flexible_eu_format_dashes() {
    let date = parse_date_flexible("15-01-2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());
}

#[test]
fn test_parse_date_flexible_natural_month_day_year() {
    let date = parse_date_flexible("January 15, 2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());

    // Abbreviated month
    let date = parse_date_flexible("Jan 15, 2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());

    // Without comma
    let date = parse_date_flexible("January 15 2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());
}

#[test]
fn test_parse_date_flexible_natural_day_month_year() {
    let date = parse_date_flexible("15 January 2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());

    // Abbreviated month
    let date = parse_date_flexible("15 Jan 2025").unwrap();
    assert_eq!(date, NaiveDate::from_ymd_opt(2025, 1, 15).unwrap());
}



// Date range tests

#[test]
fn test_temporal_query_between_iso_dates() {
    let query = TemporalQuery::parse("between 2025-01-01 and 2025-01-31").unwrap();
    let jan_15 = NaiveDate::from_ymd_opt(2025, 1, 15)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&jan_15));
    assert_eq!(query.description, "between 2025-01-01 and 2025-01-31");

    // Should not contain dates outside the range
    let feb_1 = NaiveDate::from_ymd_opt(2025, 2, 1)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(!query.period.contains(&feb_1));
}

#[test]
fn test_temporal_query_between_us_dates() {
    let query = TemporalQuery::parse("between 01/01/2025 and 01/31/2025").unwrap();
    let jan_15 = NaiveDate::from_ymd_opt(2025, 1, 15)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&jan_15));
}


#[test]
fn test_temporal_query_between_with_to() {
    // "to" should work as an alternative to "and"
    let query = TemporalQuery::parse("between 2025-01-01 to 2025-01-31").unwrap();
    let jan_15 = NaiveDate::from_ymd_opt(2025, 1, 15)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&jan_15));
}

#[test]
fn test_temporal_query_between_invalid_range() {
    // Start date after end date should fail
    let query = TemporalQuery::parse("between 2025-01-31 and 2025-01-01");
    assert!(query.is_none());
}

// Error handling tests

#[test]
fn test_parse_result_empty_input() {
    let result = TemporalQuery::parse_result("");
    assert!(matches!(result, Err(TemporalParseError::EmptyInput)));

    let result = TemporalQuery::parse_result("   ");
    assert!(matches!(result, Err(TemporalParseError::EmptyInput)));
}

#[test]
fn test_parse_result_unrecognized_pattern() {
    let result = TemporalQuery::parse_result("some random text");
    assert!(matches!(
        result,
        Err(TemporalParseError::UnrecognizedPattern { .. })
    ));
}


#[test]
fn test_parse_result_invalid_range() {
    let result = TemporalQuery::parse_result("between 2025-12-31 and 2025-01-01");
    assert!(matches!(
        result,
        Err(TemporalParseError::InvalidRange { .. })
    ));
}

#[test]
fn test_parse_result_invalid_range_start_date() {
    let result = TemporalQuery::parse_result("between not-a-date and 2025-01-31");
    assert!(matches!(
        result,
        Err(TemporalParseError::InvalidDate { .. })
    ));
}

#[test]
fn test_parse_result_success() {
    let result = TemporalQuery::parse_result("today");
    assert!(result.is_ok());
    assert_eq!(result.unwrap().description, "today");
}
