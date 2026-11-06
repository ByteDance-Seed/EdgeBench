#include <bits/stdc++.h>
using namespace std;
using i64 = long long;
#define int i64
#define rep(i, j, k) for(int i = (j); i <= (k); i++)
#define per(i, j, k) for(int i = (j); i >= (k); i--)
#define pb emplace_back
#define fi first
#define se second
using vi = vector<int>;
using pi = pair<int, int>;

template<typename T0, typename T1> bool chmin(T0 &x, const T1 &y){
	if(y < x){x = y; return true;} return false;
}
template<typename T0, typename T1> bool chmax(T0 &x, const T1 &y){
	if(x < y){x = y; return true;} return false;
}

template<typename T> void debug(char *s, T x){
	cerr << s <<" = "<< x <<endl;
}
template<typename T, typename ...Ar> void debug(char *s, T x, Ar... y){
	int dep = 0;
	while(!(*s == ',' && dep == 0)){
		if(*s == '(') dep++;
		if(*s == ')') dep--;
		cerr << *s++;
	}
	cerr <<" = "<< x <<",";
	debug(s + 1, y...);
}
#define gdb(...) debug((char*)#__VA_ARGS__, __VA_ARGS__)

const int BL = 280;

struct info{
	int l, r, sum, mx;

	info(int x = 0){
		int y = max(0ll, x);
		l = r = mx = y, sum = x;
	}
	info(int _l, int _r, int _sum, int _mx): l(_l), r(_r), sum(_sum), mx(_mx){}

	friend info operator + (const info &A, const info &B){
		return info{
			max(A.l, A.sum + B.l), 
			max(B.r, B.sum + A.r), 
			A.sum + B.sum, 
			max(max(A.mx, B.mx), A.r + B.l)
		};
	}
};

struct ansx{
	int r, mx;

	void extend(const int &B){
		mx = max(max(mx, B), r + B);
		r = max(max(0ll, B), r + B);
	}
	void extend(const info &B){
		mx = max(r + B.l, max(mx, B.mx));
		r = max(B.r, B.sum + r);
	}
};

void solve(){
	int n, q;
	cin >> n >> q;
	vi a(n);
	vector< array<int, 4> > Q(q);
	vector<ansx> ans(q, {0, 0});
	rep(i, 0, n - 1){
		cin >> a[i];
	}
	rep(i, 0, q - 1){
		rep(j, 0, 3){
			cin >> Q[i][j];
		}
		Q[i][0] --, Q[i][3] ++;
	}
	vi px(q), qx(q);
	{
		iota(px.begin(), px.end(), 0);
		sort(px.begin(), px.end(), [&](int a, int b){
			if(Q[a][2] != Q[b][2]){
				return Q[a][2] < Q[b][2];
			}
			return Q[a][3] < Q[b][3];
		});
		auto tmp = Q;
		rep(i, 0, q - 1){
			tmp[i] = Q[px[i]];
			qx[px[i]] = i;
		}
		Q = move(tmp);
	}

	vi b = a, lis = a;
	sort(lis.begin(), lis.end());
	lis.erase(unique(lis.begin(), lis.end()), lis.end());
	auto getlis = [&](int x){
		return lower_bound(lis.begin(), lis.end(), x) - lis.begin();
	};

	rep(i, 0, n - 1){
		b[i] = getlis(a[i]);
	}
	rep(i, 0, q - 1){
		Q[i][2] = getlis(Q[i][2]);
		Q[i][3] = getlis(Q[i][3]);
	}

	info buf[(BL + 2) * (BL + 1)];
	info* iS = buf;
	vector< vector<info*> > f(2, 
		vector<info*>(BL + 1));
	
	rep(j, 0, BL){
		rep(i, 0, 1){
			f[i][j] = iS - j;
			iS += (BL + 1 - j);
		}
	}

	auto solve_block = [&](int L, int R){
		int len = R - L;
		vector<signed> lis_V(lis.size() + 1);
		{// init
			vi V(b.begin() + L, b.begin() + R), tmp(len), lx(len + 1), rx(len + 1);
			auto dfs = [&](auto &self, int l, int r, bool d)->void {
				if(l + 1 == r){
					f[d][l][r] = a[L + l];
					return;
				}
				int mid = (l + r) / 2;
				self(self, l, mid, d ^ 1);
				self(self, mid, r, d ^ 1);

				int pl = l, pr = mid;
				lx[l] = pl, rx[l] = pr;
				rep(i, l, r - 1){
					if(pl < mid && (pr == r || V[pl] < V[pr])){
						tmp[i] = V[pl ++];
					} else{
						tmp[i] = V[pr ++];
					}
					lx[i + 1] = pl, rx[i + 1] = pr;
				}
				copy(tmp.begin() + l, tmp.begin() + r, V.begin() + l);
			
				rep(i, l, r - 1){
					rep(j, i + 1, r){
						f[d][i][j] = f[d ^ 1][lx[i]][lx[j]] + f[d ^ 1][rx[i]][rx[j]];
					}
				}
			};
			dfs(dfs, 0, len, 0);
			int idx = 0;
			rep(i, 0, len){
				int tmp = (i == len? int(lis_V.size()): V[i] + 1);
				fill(lis_V.begin() + idx, lis_V.begin() + tmp, i);
				idx = tmp;
			}
		}

		rep(i, 0, q - 1){
			const auto &[l, r, lv, rv] = Q[i];
			if(l > L || r < R){
				rep(j, max(L, l), min(R, r) - 1){
					if(lv <= b[j] && b[j] < rv){
						ans[i].extend(a[j]);
					}
				}
			} else{
				ans[i].extend(f[0][lis_V[lv]][lis_V[rv]]);
			}
		}
	};

	for(int i = 0; i < n; i += BL){
		solve_block(i, min(i + BL, n));
	}
	rep(i, 0, q - 1){
		cout << ans[ qx[i] ].mx <<'\n';
	}
}

signed main(){
	#ifdef LOCAL
	assert( freopen(".in", "r", stdin) );
	assert( freopen(".out", "w", stdout) );
	#endif
	ios::sync_with_stdio(0);
	cin.tie(0);

	solve();
}
