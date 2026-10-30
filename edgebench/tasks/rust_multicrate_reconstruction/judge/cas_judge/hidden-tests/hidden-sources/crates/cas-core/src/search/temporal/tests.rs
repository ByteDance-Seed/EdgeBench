#[test]
fn test_time_period_day() {
    let date = NaiveDate::from_ymd_opt(2025, 1, 15).unwrap();
    let period = TimePeriod::day(date);

    // Start of day
    let start_dt = date.and_hms_opt(0, 0, 0).unwrap().and_utc();
    assert!(period.contains(&start_dt));

    // End of day
    let end_dt = date.and_hms_opt(23, 59, 59).unwrap().and_utc();
    assert!(period.contains(&end_dt));

    // Next day
    let next_day = date
        .succ_opt()
        .unwrap()
        .and_hms_opt(0, 0, 1)
        .unwrap()
        .and_utc();
    assert!(!period.contains(&next_day));
}

#[test]
fn test_time_period_month() {
    let period = TimePeriod::month(2025, 1).unwrap();

    // Jan 1
    let jan1 = NaiveDate::from_ymd_opt(2025, 1, 1)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(period.contains(&jan1));

    // Jan 31
    let jan31 = NaiveDate::from_ymd_opt(2025, 1, 31)
        .unwrap()
        .and_hms_opt(23, 59, 0)
        .unwrap()
        .and_utc();
    assert!(period.contains(&jan31));

    // Feb 1
    let feb1 = NaiveDate::from_ymd_opt(2025, 2, 1)
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap()
        .and_utc();
    assert!(!period.contains(&feb1));
}

#[test]
fn test_temporal_query_parse_today() {
    let query = TemporalQuery::parse("today").unwrap();
    assert!(query.period.contains(&Utc::now()));
}

#[test]
fn test_temporal_query_parse_last_n_days() {
    let query = TemporalQuery::parse("last 30 days").unwrap();
    let days_ago = Utc::now() - Duration::days(25);
    assert!(query.period.contains(&days_ago));
}

#[test]
fn test_temporal_query_parse_iso_date() {
    let query = TemporalQuery::parse("2025-01-15").unwrap();
    let dt = NaiveDate::from_ymd_opt(2025, 1, 15)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&dt));
}

#[test]
fn test_temporal_query_parse_recently() {
    let query = TemporalQuery::parse("recently").unwrap();
    let days_ago_5 = Utc::now() - Duration::days(5);
    assert!(query.period.contains(&days_ago_5));
    assert_eq!(query.description, "recently");
}

#[test]
fn test_temporal_query_parse_this_year() {
    let before = Utc::now();
    let query = TemporalQuery::parse("this year").unwrap();
    assert!(query.period.contains(&before));
    assert_eq!(query.description, "this year");
}

#[test]
fn test_temporal_query_with_flexible_date() {
    // US format
    let query = TemporalQuery::parse("01/15/2025").unwrap();
    let expected = NaiveDate::from_ymd_opt(2025, 1, 15).unwrap();
    assert!(
        query
            .period
            .contains(&expected.and_hms_opt(12, 0, 0).unwrap().and_utc())
    );

    // Natural format
    let query = TemporalQuery::parse("January 15, 2025").unwrap();
    assert!(
        query
            .period
            .contains(&expected.and_hms_opt(12, 0, 0).unwrap().and_utc())
    );
}

#[test]
fn test_temporal_query_since_flexible_date() {
    let query = TemporalQuery::parse("since 01/01/2025").unwrap();
    let jan_15 = NaiveDate::from_ymd_opt(2025, 1, 15)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&jan_15));
    assert_eq!(query.description, "since 01/01/2025");
}

#[test]
fn test_temporal_query_between_natural_dates() {
    let query = TemporalQuery::parse("between January 1, 2025 and January 31, 2025").unwrap();
    let jan_15 = NaiveDate::from_ymd_opt(2025, 1, 15)
        .unwrap()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc();
    assert!(query.period.contains(&jan_15));
}

#[test]
fn test_parse_result_invalid_since_date() {
    let result = TemporalQuery::parse_result("since not-a-date");
    assert!(matches!(
        result,
        Err(TemporalParseError::InvalidDate { .. })
    ));
}
