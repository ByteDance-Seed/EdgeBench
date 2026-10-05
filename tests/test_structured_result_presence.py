"""Result-presence regression tests through the public grading entrypoint."""
import unittest

from sforge.harness.grading import grade_output
from sforge.harness.task_spec import TaskSpec, WorkSpec, JudgeSpec


def spec():
    return TaskSpec("synthetic", "Synthetic", "python", "linux/amd64", "/workspace",
                    [], [], WorkSpec("specs", "task"),
                    JudgeSpec("evaluate", 60, "structured_json"))


def marked(body):
    return ">>>>> Start Structured Result\n" + body + "\n>>>>> End Structured Result"


class ResultPresenceTest(unittest.TestCase):
    def test_missing_or_malformed_result_is_invalid_not_zero(self):
        for output in ("", "error: build failed\nExit code: 1", "{}",
                       marked("{"), marked("[]"), marked("null"), marked('"text"')):
            with self.subTest(output=output):
                report = grade_output(spec(), output, "submission", runtime=12.5)
                self.assertFalse(report.valid)
                self.assertIsNone(report.score)
                self.assertEqual(report.total_tests, 0)
                self.assertIn("No structured evaluation result", report.summary)
                self.assertEqual(report.runtime_seconds, 12.5)
                self.assertEqual(report.raw_output, output)

    def test_timeout_metadata_is_retained(self):
        report = grade_output(spec(), "partial log", "submission", timed_out=True)
        self.assertTrue(report.timed_out)
        self.assertFalse(report.valid)

    def test_total_score_fallback_including_zero_is_unchanged(self):
        for score in (0, 2.5):
            report = grade_output(spec(), f"TOTAL_SCORE {score}", "submission")
            self.assertTrue(report.valid)
            self.assertEqual(report.score, score)

    def test_explicit_zero_and_invalid_result_are_preserved(self):
        for valid in (True, False):
            body = '{"score":0,"valid":' + str(valid).lower() + '}'
            report = grade_output(spec(), marked(body), "submission")
            self.assertIs(report.valid, valid)
            self.assertEqual(report.score, 0)

    def test_pass_rate_only_and_details_only_are_supported(self):
        for body in ('{"pass_rate":0.5}', '{"details":[{"name":"x","status":"PASSED"}]}'):
            report = grade_output(spec(), marked(body), "submission")
            self.assertTrue(report.valid)
            self.assertIsNone(report.score)
            self.assertGreater(report.pass_rate, 0)


if __name__ == "__main__":
    unittest.main()
