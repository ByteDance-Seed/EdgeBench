"""Aggregate scheduling invariants, independent of any benchmark grader."""
import threading
from concurrent.futures import ThreadPoolExecutor
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from sforge.harness import judge_server as js
from sforge.harness.config import SForgeConfig, load_config


@pytest.fixture
def judge(tmp_path, monkeypatch):
    monkeypatch.setattr(js, 'create_backend_from_config', lambda c: object())
    state = js.JudgeState(SForgeConfig(log_dir=tmp_path, judge_max_concurrent=1, judge_max_pending=1))
    state.tasks['test'] = SimpleNamespace(judge=SimpleNamespace(selection='pass_rate_first', score_direction='maximize'))
    yield state
    state.close()


def test_concurrency_fifo_spooling_and_retry_does_not_spend(judge, monkeypatch):
    entered, release = threading.Event(), threading.Event()
    seen = []
    def grade(**kw):
        seen.append(kw['archive'])
        entered.set()
        assert release.wait(5)
        return SimpleNamespace(to_dict=lambda: {'score': 7, 'pass_rate': 1})
    monkeypatch.setattr(js, 'judge_submission', grade)
    token = judge.register_session('test', 'run', max_agent_submissions=3)
    first, r1, _ = judge.submit_for_token(token, b'first', 'agent')
    assert entered.wait(2)
    second, r2, _ = judge.submit_for_token(token, b'second', 'agent')
    before = judge.resolve_token(token)
    with pytest.raises(js.JudgeCapacityExceeded):
        judge.submit_for_token(token, b'third', 'agent')
    assert judge.resolve_token(token) == before  # both budget and cooldown
    assert (r1, r2) == ('agent-1', 'agent-2')
    assert judge.get_result(first)['status'] == js.SubmissionStatus.RUNNING
    assert judge.get_result(second)['status'] == js.SubmissionStatus.QUEUED
    assert sorted(p.read_bytes() for p in (judge.config.log_dir / 'judge-pending').glob('*')) == [b'first', b'second']
    assert seen == [b'first']
    release.set()
    judge._executor.submit(lambda: None).result(timeout=5)
    third, r3, remaining = judge.submit_for_token(token, b'third', 'agent')
    assert (r3, remaining) == ('agent-3', 0)
    judge.close()
    assert seen == [b'first', b'second', b'third']
    assert judge.get_result(second)['status'] == js.SubmissionStatus.COMPLETED
    assert not list((judge.config.log_dir / 'judge-pending').glob('*'))
    with pytest.raises(js.JudgeCapacityExceeded):
        judge.submit('test', b'after-close')


def test_simultaneous_runs_share_server_limit(judge, monkeypatch):
    release = threading.Event()
    def grade(**kw):
        assert release.wait(5)
        return SimpleNamespace(to_dict=lambda: {'pass_rate': 1})
    monkeypatch.setattr(js, 'judge_submission', grade)
    tokens = [judge.register_session('test', f'run-{n}') for n in range(12)]
    def submit(token):
        try:
            return judge.submit_for_token(token, b'archive', 'auto')
        except js.JudgeCapacityExceeded:
            return None
    try:
        with ThreadPoolExecutor(max_workers=12) as pool:
            results = list(pool.map(submit, tokens))
        assert sum(r is not None for r in results) == 2
        assert sum(judge.resolve_token(t)['next_auto'] - 1 for t in tokens) == 2
    finally:
        release.set()


def test_failures_release_capacity_and_keep_errors_out_of_completed(judge, monkeypatch):
    def grade(**kw):
        raise RuntimeError('synthetic evaluator failure')
    monkeypatch.setattr(js, 'judge_submission', grade)
    first = judge.submit('test', b'bad', 'run', 'auto-1')
    second = judge.submit('test', b'bad2', 'run', 'auto-2')
    judge.close()
    for sid in (first, second):
        assert judge.get_result(sid)['status'] == js.SubmissionStatus.ERROR
    assert all(e['status'] == 'error' for e in judge.run_history['run/test'])
    assert judge._capacity.acquire(False)
    assert judge._capacity.acquire(False)


def test_disk_and_budget_failure_release_reservation(judge, monkeypatch):
    token = judge.register_session('test', 'run', max_agent_submissions=0)
    with pytest.raises(js.SubmissionBudgetExceeded):
        judge.submit_for_token(token, b'no', 'agent')
    assert not list((judge.config.log_dir / 'judge-pending').glob('*'))
    def fail(_):
        raise OSError('disk full')
    monkeypatch.setattr(judge, '_spool', fail)
    for _ in range(4):
        with pytest.raises(OSError):
            judge.submit_for_token(token, b'no', 'auto')
    assert judge.resolve_token(token)['next_auto'] == 1


def test_http_backpressure_auth_and_result_contract(tmp_path, monkeypatch):
    monkeypatch.setattr(js, 'create_backend_from_config', lambda c: object())
    monkeypatch.setattr(js.JudgeState, 'load_tasks', lambda self: self.tasks.update(test=object()))
    release, entered = threading.Event(), threading.Event()
    def grade(**kw):
        entered.set()
        assert release.wait(5)
        return SimpleNamespace(to_dict=lambda: {'pass_rate': 1})
    monkeypatch.setattr(js, 'judge_submission', grade)
    app = js.create_app(SForgeConfig(log_dir=tmp_path, judge_max_concurrent=1, judge_max_pending=0))
    token = app.state.judge.register_session('test', 'run')
    with TestClient(app) as client:
        try:
            first = client.post('/api/v1/submit', data={'token': token}, files={'archive': ('a.tar.gz', b'one')})
            assert first.status_code == 200
            assert entered.wait(2)
            full = client.post('/api/v1/submit', data={'token': token}, files={'archive': ('a.tar.gz', b'two')})
            assert full.status_code == 503 and full.headers['retry-after'] == '5'
            invalid = client.post('/api/v1/submit', data={'token': 'invalid'}, files={'archive': ('a', b'x')})
            assert invalid.status_code == 401
            auto = client.post('/api/v1/submit', data={'token': token, 'kind': 'auto'}, files={'archive': ('a', b'x')})
            assert auto.status_code == 403
            result = client.get('/api/v1/result/' + first.json()['submission_id'])
            assert result.json()['status'] == 'running'
            assert app.state.judge.resolve_token(token)['next_agent'] == 2
        finally:
            release.set()


@pytest.mark.parametrize('workers,pending', [(0, 1), (-1, 1), (1, -1)])
def test_invalid_capacity_rejected(tmp_path, workers, pending):
    with pytest.raises(ValueError):
        js.JudgeState(SForgeConfig(log_dir=tmp_path, judge_max_concurrent=workers, judge_max_pending=pending))


def test_capacity_environment(monkeypatch):
    monkeypatch.setenv('SFORGE_JUDGE_MAX_CONCURRENT', '3')
    monkeypatch.setenv('SFORGE_JUDGE_MAX_PENDING', '7')
    config = load_config()
    assert (config.judge_max_concurrent, config.judge_max_pending) == (3, 7)


def test_pending_and_invalid_are_not_zero_score_observations(tmp_path):
    import json
    from sforge.visualizer.scanner import _scan_submissions_shallow
    root = tmp_path / 'submissions'
    for n in range(1, 5):
        (root / f'auto-{n}').mkdir(parents=True)
    # Missing and partially written reports are pending, not zero.
    (root / 'auto-2' / 'report.json').write_text('{')
    (root / 'auto-3' / 'report.json').write_text(json.dumps({'valid': False, 'score': 0}))
    (root / 'auto-4' / 'report.json').write_text(json.dumps({'valid': True, 'score': 0, 'pass_rate': 0, 'submitted_at': 123}))
    rows = _scan_submissions_shallow(tmp_path)
    assert [(r.round_label, r.score, r.submitted_at) for r in rows] == [('auto-4', 0, 123)]
