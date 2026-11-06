#include <bits/stdc++.h>
#define ull unsigned long long
#define ll long long
#define uint unsigned
#define pb push_back
#define mkp make_pair
#define fi first
#define se second
#define inf 1000000000
#define infll 1000000000000000000ll
#define pii pair<int,int>
#define rep(i,a,b,c) for(int i=(a);i<=(b);i+=(c))
#define per(i,a,b,c) for(int i=(a);i>=(b);i-=(c))
#define F(i,a,b) for(int i=a,i##end=b;i<=i##end;i++)
#define dF(i,a,b) for(int i=a,i##end=b;i>=i##end;i--)
#define lowbit(x) ((x)&(-(x)))
#define HH printf("\n")
#define eb emplace_back
#define SZ(x) ((int)x.size())
#define all(x) x.begin(),x.end()
using namespace std;
void fre() {
    // freopen("shope.in","r",stdin),freopen("shope.out","w",stdout);
}
bool ST;
template<typename T>inline void chkmax(T &x, const T &y) {
    x = std::max(x, y);
}
template<typename T>inline void chkmin(T &x, const T &y) {
    x = std::min(x, y);
}
const int mod = 998244353, maxn = 500005;
inline int qpow(int x, ll y) {
    int res = 1;

    for (; y; y >>= 1, x = 1ll * x * x % mod)
        if (y & 1)
            res = 1ll * res * x % mod;

    return res;
}
inline void inc(int &x, const int y) {
    x = (x + y >= mod) ? (x + y - mod) : (x + y);
}
inline void dec(int &x, const int y) {
    x = (x >= y) ? (x - y) : (x + mod - y);
}
inline int add(const int x, const int y) {
    return (x + y >= mod) ? (x + y - mod) : (x + y);
}
inline int sub(const int x, const int y) {
    return (x >= y) ? (x - y) : (x + mod - y);
}
int n, zsy, a[maxn], fa[maxn];
vector<int>g[maxn];
const int B = 100;
int pre[B + 5][maxn], h[maxn], q[maxn], dis[maxn], to[maxn];
bool fl[maxn];
namespace seg {
int ls[maxn << 5], rs[maxn << 5], t[maxn << 5], tot;
void update(int &o, int l, int r, int pos, int val) {
    if (!o)
        o = ++tot;

    inc(t[o], val);

    if (l == r)
        return;

    int mid = (l + r) >> 1;
    (pos <= mid) ? update(ls[o], l, mid, pos, val) : update(rs[o], mid + 1, r, pos, val);
}
int query(int o, int l, int r, int ql, int qr) {
    if (ql > qr || !o)
        return 0;

    if (ql <= l && qr >= r)
        return t[o];

    int res = 0, mid = (l + r) >> 1;

    if (ql <= mid)
        res = query(ls[o], l, mid, ql, qr);

    if (qr > mid)
        inc(res, query(rs[o], mid + 1, r, ql, qr));

    return res;
}
int merge(int x, int y) {
    if (!x || !y)
        return x ^ y;

    int o = ++tot;
    ls[o] = merge(ls[x], ls[y]), rs[o] = merge(rs[x], rs[y]), t[o] = add(t[x], t[y]);
    return o;
}
}
int rt[maxn], nxt[maxn];
void solve() {
    cin >> n >> zsy;
    F(i, 1, n)cin >> a[i];
    F(i, 2, n)cin >> fa[i], g[fa[i]].push_back(i);

    dF(i, n, 1)for (int j : g[i])
        chkmax(h[i], h[j] + 1);

    F(i, 1, n)if (h[i] > B)
        fl[i] = 1;

    F(i, 1, n)if (!fl[i]) {
        int qL = 1, qR = 0, sum = 0;
        dis[q[++qR] = i] = 0;

        while (qL <= qR) {
            const int u = q[qL++];
            pre[dis[u]][u] = add(1ll * a[u] * a[u] % mod, 2ll * sum * a[u] % mod), inc(sum, a[u]);

            if (dis[u] == B)
                continue;

            for (int v : g[u])
                dis[q[++qR] = v] = dis[u] + 1;
        }
    }

    F(i, 0, B)F(j, 1, n)inc(pre[i][j], pre[i][j - 1]);
    nxt[n + 1] = n + 1, to[n + 1] = n + 1;
    dF(i, n, 1)to[i] = g[i].empty() ? to[i + 1] : g[i][0];
    dF(i, n, 1) {
        seg::update(rt[i], 1, n, i, a[i]);

        for (int j : g[i])
            rt[i] = seg::merge(rt[i], rt[j]);
    }
    dF(i, n, 1)nxt[i] = fl[i] ? i : nxt[i + 1];
    int lastans = 0;
    F(_, 1, zsy) {
        int l, r;
        cin >> l >> r, l ^= lastans, r ^= lastans;
        int ans = 0, u = l;
        F(d, 0, B) {
            if (u > r)
                break;

            inc(ans, sub(pre[d][min(to[u] - 1, r)], pre[d][u - 1])), u = to[u];
        }

        for (u = nxt[l]; u <= min(r, to[l] - 1); u = nxt[u + 1])
            if (fl[u]) {
                const int val = seg::query(rt[u], 1, n, l, r);
                inc(ans, 1ll * val * val % mod);
            }

        cout << (lastans = ans) << '\n';
    }
}
bool ED;
signed main() {
    fre(), ios::sync_with_stdio(0), cin.tie(0), cout.tie(0);
    int zsy = 1;
    F(____, 1, zsy)solve();
}
