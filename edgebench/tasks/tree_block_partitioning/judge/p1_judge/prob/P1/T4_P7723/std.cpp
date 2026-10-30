#include "data.h"
#include <bits/stdc++.h>
#define F(i, l, r) for (int i = l; i < r; ++i)

const int B = 1007, N = 5e5 + 7;

struct Pos {
  int x, y;
  Data d;
} ps[N];

int n;
const Operation (*o)[3][3];
Data (*ans)[3][3];
int xr[N], yr[N];

char pool[100000000], *pool_p = pool;

template <class T = int> T *alloc(int n) {
  int sz = n * sizeof(T);
  T *p = (T *)pool_p;
  pool_p += sz;
  for (int i = 0; i < n; ++i)
    p[i] = T();
  return p;
}

struct Free {
  char *p;
  Free() { p = pool_p; }
  ~Free() { pool_p = p; }
};

int *pfxsum(int *x, int n) {
  int *s = alloc(n);
  int S = 0;
  F(i, 0, n) s[i] = S, S += x[i];
  return s;
}

struct Info {
  int *len;
  int *pos;
  int sz;
  int *id1, *id2;
  Info duel() {
    int *l = alloc(sz);
    int *p = alloc(sz);
    F(i, 0, sz) {
      int j = pos[i];
      l[j] = len[i];
      p[j] = i;
    }
    return Info{l, p, sz};
  }
  void R(int *rs) {
    int p = 0;
    F(i, 0, sz) {
      int c = len[i];
      F(j, 0, c) rs[p++] = i;
    }
  }
  void D(int *as) {
    Info d = duel();
    int p = 0;
    int *s = pfxsum(len, sz);
    F(i, 0, d.sz) {
      int b = s[d.pos[i]];
      int c = d.len[i];
      F(j, 0, c) as[b + j] = p - b;
      p += c;
    }
  }
};

struct DO {
  Data *d_;
  Operation *o_;
  int xsz, ysz;
  DO(int xsz, int ysz) {
    int sz = xsz * ysz;
    d_ = alloc<Data>(sz);
    o_ = alloc<Operation>(sz);
    this->xsz = xsz;
    this->ysz = ysz;
  }
  void up(int *xr, int *yr, DO &w) {
    F(i, 0, w.xsz) F(j, 0, w.ysz) d(xr[i], yr[j]).add_eq(w.d(i, j));
  }
  void dn(int *xr, int *yr, DO &w, bool flag) {
    F(i, 0, w.xsz) F(j, 0, w.ysz) w.app(i, j, o(xr[i], yr[j]), flag);
  }
  void app(int x, int y, const Operation &op, bool flag) {
    if (flag)
      op.apply(d(x, y));
    op.apply(o(x, y));
  }
  Data &d(int x, int y) { return d_[x * ysz + y]; }
  Operation &o(int x, int y) { return o_[x * ysz + y]; }
};

struct Node {
  Info x, y;
  Node *lc, *rc;
  void rec(DO &w, int *x1, int *y1, Node *c, bool flag) {
    DO w1(c->x.sz, c->y.sz);
    w1.up(x1, y1, w);
    c->dc(w1);
    w1.dn(x1, y1, w, flag);
  }
  void dc(DO &w) {
    Free _;
    if (lc) {
      rec(w, x.id1, y.id1, lc, 1);
      rec(w, x.id2, y.id2, rc, 0);
    } else {
      F(i, 0, 3) F(j, 0, 3) {
        ans[0][i][j].add_eq(w.d(i, j));
        w.app(i, j, o[0][i][j], 0);
      }
      ++ans, ++o;
    }
  }
  void solve() {
    x.R(xr), y.R(yr);
    DO w(x.sz, y.sz);
    F(i, 0, n) w.d(xr[ps[i].x], yr[ps[i].y]).add_eq(ps[i].d);
    dc(w);
    F(i, 0, n) w.o(xr[ps[i].x], yr[ps[i].y]).apply(ps[i].d);
    x.D(xr), y.D(yr);
    F(i, 0, n) {
      ps[i].x += xr[ps[i].x];
      ps[i].y += yr[ps[i].y];
    }
  }
};

Info U(int x1, int x2) {
  assert(0 < x1 && x1 < x2 && x2 < n);
  int *len = alloc(3);
  int *pos = alloc(3);
  len[0] = x1;
  len[1] = x2 - x1;
  len[2] = n - x2;
  pos[0] = 0;
  pos[1] = 2;
  pos[2] = 1;
  return Info{len, pos, 3};
};

Info A(Info &i1, Info &i2) {
  int sz = i1.sz + i2.sz;
  int *len = alloc(sz);
  int *pos = alloc(sz);
  int *id1 = alloc(sz);
  int *id2 = alloc(sz);
  Free _;
  int *len_m = alloc(sz);
  int *pos_m = alloc(sz);
  int *cnt0 = alloc(i1.sz);
  int *cnt1 = alloc(i1.sz);
  int *cnt2 = alloc(i2.sz);
  int *cnt3 = alloc(i2.sz);
  Info m1 = i1.duel();
  int p1 = 0, p2 = 0, p = 0;
  int s1 = i1.len[0], s2 = i2.len[0];
  for (;;) {
    ++cnt1[p1];
    ++cnt2[p2];
    if (s1 < s2) {
      len_m[p++] = s1;
      s2 -= s1;
      s1 = m1.len[++p1];
    } else if (s1 > s2) {
      len_m[p++] = s2;
      s1 -= s2;
      s2 = i2.len[++p2];
    } else {
      len_m[p++] = s1;
      if (++p1 >= m1.sz)
        break;
      s1 = m1.len[p1];
      s2 = i2.len[++p2];
    }
  }
  F(i, 0, m1.sz) cnt0[m1.pos[i]] = cnt1[i];
  F(i, 0, i2.sz) cnt3[i2.pos[i]] = cnt2[i];
  int *s0 = pfxsum(cnt0, m1.sz);
  int *s3 = pfxsum(cnt3, i2.sz);
  p = 0;
  F(i, 0, i2.sz) {
    int c = cnt2[i];
    int b = s3[i2.pos[i]];
    F(j, 0, c) pos_m[p++] = b + j;
  }
  p = 0;
  s2 = cnt2[0];
  p2 = 0;
  F(i, 0, m1.sz) {
    int k = m1.pos[i];
    int c = cnt1[i];
    int b = s0[k];
    F(j, 0, c) {
      id1[b + j] = k;
      id2[b + j] = p2;
      pos[b + j] = pos_m[p];
      len[b + j] = len_m[p++];
      if (!--s2)
        s2 = cnt2[++p2];
    }
  }
  return Info{len, pos, p, id1, id2};
}

Node *solve(const int m, const int x1[], const int x2[], const int y1[],
            const int y2[]) {
  Node *ret = alloc<Node>(1);
  if (m == 1) {
    *ret = Node{U(*x1, *x2), U(*y1, *y2), NULL, NULL};
  } else {
    int m0 = m / 2;
    Node *n1 = solve(m0, x1, x2, y1, y2);
    Node *n2 = solve(m - m0, x1 + m0, x2 + m0, y1 + m0, y2 + m0);
    *ret = Node{A(n1->x, n2->x), A(n1->y, n2->y), n1, n2};
  }
  return ret;
}

void solve(const int n, const int m, const int p[], const Data d[],
           const int x1[], const int x2[], const int y1[], const int y2[],
           const Operation o[][3][3], Data ans[][3][3]) {
  ::n = n;
  ::o = o;
  ::ans = ans;
  F(i, 0, n) ps[i] = Pos{i, p[i], d[i]};
  int B = sqrt(n / 3) / 2 + 1;
  fprintf(stderr, ">>> %d\n",
          (m / B + 1) * (n + B * B * 8) + (m / B + 1) * (n + B * B * 8) +
              (m / B + 1) * (B * B * 8));
  for (int i = 0; i < m; i += B) {
    Free _;
    solve(std::min(B, m - i), x1 + i, x2 + i, y1 + i, y2 + i)->solve();
  }
}
